import os
import sys
import argparse
import boto3

class Logger:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

    @staticmethod
    def info(msg):
        print(f"ℹ️ {Logger.BLUE}[INFO]{Logger.RESET} {msg}")

    @staticmethod
    def success(msg):
        print(f"✅ {Logger.GREEN}[SUCCESS]{Logger.RESET} {msg}")

    @staticmethod
    def warning(msg):
        print(f"⚠️ {Logger.YELLOW}[WARNING]{Logger.RESET} {msg}")

    @staticmethod
    def error(msg):
        print(f"❌ {Logger.RED}[ERROR]{Logger.RESET} {msg}", file=sys.stderr)

    @staticmethod
    def stage(msg):
        print(f"\n{Logger.BOLD}🚀 {msg}{Logger.RESET}")

    @staticmethod
    def start_group(name):
        if os.environ.get('GITHUB_ACTIONS') == 'true':
            print(f"::group::📁 {name}")
        else:
            print(f"\n--- 📁 {name} ---")

    @staticmethod
    def end_group():
        if os.environ.get('GITHUB_ACTIONS') == 'true':
            print("::endgroup::")
        else:
            print("-" * 40)

def get_clusters(ecs, tag_key=None, tag_value=None):
    if tag_key and tag_value:
        Logger.info(f"Querying Resource Groups Tagging API for ECS clusters with tag: {tag_key}={tag_value}")
        try:
            client = boto3.client('resourcegroupstaggingapi')
            paginator = client.get_paginator('get_resources')
            cluster_arns = []
            for page in paginator.paginate(
                TagFilters=[{'Key': tag_key, 'Values': [tag_value]}],
                ResourceTypeFilters=['ecs:cluster']
            ):
                for resource in page.get('ResourceTagMappingList', []):
                    cluster_arns.append(resource['ResourceARN'])
            Logger.info(f"Found {len(cluster_arns)} ECS cluster(s) with tag: {tag_key}={tag_value}")
            return cluster_arns
        except Exception as e:
            Logger.error(f"Failed to query Resource Groups Tagging API: {e}")
            Logger.info("Falling back to listing all clusters in region...")

    paginator = ecs.get_paginator('list_clusters')
    cluster_arns = []
    for page in paginator.paginate():
        cluster_arns.extend(page.get('clusterArns', []))
    return cluster_arns

def main():
    parser = argparse.ArgumentParser(description="Manage Dynatrace OneAgent on ECS Clusters")
    parser.add_argument('--observe', action='store_true', help="Collect clusters and observe OneAgent status (installed / not installed)")
    parser.add_argument('--install', action='store_true', help="Install OneAgent in clusters who don't have it")
    parser.add_argument('--cluster', help="Specify a target ECS cluster name to restrict action to")
    parser.add_argument('--tag-key', help="AWS Tag key to filter clusters by (fallback: PROJECT_TAG_KEY env var)")
    parser.add_argument('--tag-value', help="AWS Tag value to filter clusters by (fallback: PROJECT_TAG_VALUE env var)")
    args = parser.parse_args()

    ecs = boto3.client('ecs')
    
    environment = os.environ.get('ENVIRONMENT', 'production')
    oneagent_arn = os.environ.get('ONEAGENT_TASK_DEFINITION_ARN')
    service_name = f"dynatrace-oneagent-{environment}"

    # Read tags from arguments or environment
    tag_key = args.tag_key or os.environ.get('PROJECT_TAG_KEY')
    tag_value = args.tag_value or os.environ.get('PROJECT_TAG_VALUE')

    if args.observe:
        Logger.stage("COLLECTING CLUSTERS & OBSERVING INSTALLED STATUS")
        try:
            cluster_arns = get_clusters(ecs, tag_key=tag_key, tag_value=tag_value)
            Logger.info(f"Scanning {len(cluster_arns)} ECS cluster(s).\n")
        except Exception as e:
            Logger.error(f"Failed to obtain ECS clusters: {e}")
            sys.exit(1)

        for cluster_arn in cluster_arns:
            cluster_name = cluster_arn.split('/')[-1]
            if args.cluster and cluster_name != args.cluster:
                continue
            
            Logger.start_group(f"Inspecting Cluster: {cluster_name}")
            try:
                srv_paginator = ecs.get_paginator('list_services')
                service_arns = []
                for srv_page in srv_paginator.paginate(cluster=cluster_arn):
                    service_arns.extend(srv_page.get('serviceArns', []))
                
                has_oneagent = any(arn.split('/')[-1] == service_name for arn in service_arns)
                if has_oneagent:
                    Logger.success(f"Cluster '{cluster_name}' -> STATUS: Dynatrace OneAgent is INSTALLED")
                else:
                    Logger.warning(f"Cluster '{cluster_name}' -> STATUS: Dynatrace OneAgent is NOT INSTALLED")
            except Exception as e:
                Logger.error(f"Failed to inspect cluster '{cluster_name}': {e}")
            Logger.end_group()

    elif args.install:
        Logger.stage("INSTALLING ONEAGENT IN CLUSTERS LACKING IT")
        if not oneagent_arn:
            Logger.error("ONEAGENT_TASK_DEFINITION_ARN environment variable is missing.")
            sys.exit(1)

        try:
            cluster_arns = get_clusters(ecs, tag_key=tag_key, tag_value=tag_value)
        except Exception as e:
            Logger.error(f"Failed to obtain ECS clusters: {e}")
            sys.exit(1)

        for cluster_arn in cluster_arns:
            cluster_name = cluster_arn.split('/')[-1]
            if args.cluster and cluster_name != args.cluster:
                continue
            
            Logger.start_group(f"Processing Cluster: {cluster_name}")
            try:
                srv_paginator = ecs.get_paginator('list_services')
                service_arns = []
                for srv_page in srv_paginator.paginate(cluster=cluster_arn):
                    service_arns.extend(srv_page.get('serviceArns', []))
                
                has_oneagent = any(arn.split('/')[-1] == service_name for arn in service_arns)
                if not has_oneagent:
                    Logger.info(f"Cluster '{cluster_name}' lacks OneAgent. Starting deployment...")
                    ecs.create_service(
                        cluster=cluster_arn,
                        serviceName=service_name,
                        taskDefinition=oneagent_arn,
                        schedulingStrategy='DAEMON',
                        launchType='EC2'
                    )
                    Logger.success(f"Scheduled Dynatrace OneAgent daemon service on cluster '{cluster_name}'")
                else:
                    Logger.info(f"Cluster '{cluster_name}' already has OneAgent. Skipping installation.")
            except Exception as e:
                Logger.error(f"Failed to deploy on cluster '{cluster_name}': {e}")
            Logger.end_group()

    else:
        parser.print_help()

if __name__ == '__main__':
    main()
