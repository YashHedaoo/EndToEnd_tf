import os
import sys
import boto3

def main():
    print("=== [STAGE 1] INITIALIZING AWS CLIENTS ===")
    ecs = boto3.client('ecs')
    
    environment = os.environ.get('ENVIRONMENT', 'production')
    oneagent_arn = os.environ.get('ONEAGENT_TASK_DEFINITION_ARN')
    service_name = f"dynatrace-oneagent-{environment}"

    if not oneagent_arn:
        print("[ERROR] ONEAGENT_TASK_DEFINITION_ARN environment variable is missing.")
        sys.exit(1)

    print("=== [STAGE 2] COLLECTING ECS CLUSTERS ===")
    try:
        paginator = ecs.get_paginator('list_clusters')
        cluster_arns = []
        for page in paginator.paginate():
            cluster_arns.extend(page.get('clusterArns', []))
        
        cluster_names = [arn.split('/')[-1] for arn in cluster_arns]
        print(f"[INFO] Discovered {len(cluster_names)} ECS Cluster(s): {cluster_names}")
    except Exception as e:
        print(f"[ERROR] Failed to list ECS clusters: {e}")
        sys.exit(1)

    print("=== [STAGE 3] OBSERVING DYNATRACE ONEAGENT INSTALLATIONS ===")
    for cluster_arn in cluster_arns:
        cluster_name = cluster_arn.split('/')[-1]
        print(f"\n--- Checking Cluster: {cluster_name} ---")
        
        try:
            # List services
            srv_paginator = ecs.get_paginator('list_services')
            service_arns = []
            for srv_page in srv_paginator.paginate(cluster=cluster_arn):
                service_arns.extend(srv_page.get('serviceArns', []))
            
            # Check for OneAgent
            has_oneagent = False
            for service_arn in service_arns:
                if service_arn.split('/')[-1] == service_name:
                    has_oneagent = True
                    break
            
            if has_oneagent:
                print(f"[OK] Dynatrace OneAgent is already installed and active on cluster '{cluster_name}'.")
            else:
                print(f"[WARNING] Dynatrace OneAgent is missing on cluster '{cluster_name}'!")
                print(f"[ACTION] Installing Dynatrace OneAgent on cluster '{cluster_name}'...")
                
                # Deploy daemon service
                ecs.create_service(
                    cluster=cluster_arn,
                    serviceName=service_name,
                    taskDefinition=oneagent_arn,
                    schedulingStrategy='DAEMON',
                    launchType='EC2'
                )
                print(f"[SUCCESS] Successfully scheduled Dynatrace OneAgent daemon on cluster '{cluster_name}'.")
        except Exception as e:
            print(f"[ERROR] Failed to observe/install on cluster '{cluster_name}': {e}")
            continue

if __name__ == '__main__':
    main()
