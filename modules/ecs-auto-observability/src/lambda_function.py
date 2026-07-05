import os
import logging
import boto3

# Set up logging configuration
logger = logging.getLogger()
logger.setLevel(logging.INFO)

ecs_client = boto3.client('ecs')

def lambda_handler(event, context):
    logger.info("Starting Dynatrace OneAgent ECS Auto-Observability Scan...")

    # Fetch environment configurations
    environment = os.environ.get('ENVIRONMENT', 'dev')
    oneagent_task_def_arn = os.environ.get('ONEAGENT_TASK_DEFINITION_ARN')
    service_name = f"dynatrace-oneagent-{environment}"

    if not oneagent_task_def_arn:
        logger.error("ONEAGENT_TASK_DEFINITION_ARN environment variable is not defined.")
        return {"status": "error", "message": "ONEAGENT_TASK_DEFINITION_ARN not defined"}

    # Retrieve and parse monitored clusters whitelist
    monitored_clusters_raw = os.environ.get('MONITORED_CLUSTERS', '*')
    monitored_clusters = [c.strip() for c in monitored_clusters_raw.split(',') if c.strip()]

    try:
        # 1. Discover all ECS clusters in the targeted region
        paginator = ecs_client.get_paginator('list_clusters')
        cluster_arns = []
        for page in paginator.paginate():
            cluster_arns.extend(page.get('clusterArns', []))

        logger.info(f"Discovered {len(cluster_arns)} ECS cluster(s) in region.")

        # 2. Iterate through each cluster to verify OneAgent Daemon service
        for cluster_arn in cluster_arns:
            cluster_name = cluster_arn.split('/')[-1]
            
            # Check whitelist matching
            if '*' not in monitored_clusters and cluster_name not in monitored_clusters:
                logger.info(f"Cluster {cluster_name} is not in MONITORED_CLUSTERS whitelist. Skipping Dynatrace OneAgent installation.")
                continue

            logger.info(f"Checking cluster: {cluster_name}")

            # List all services inside the cluster
            srv_paginator = ecs_client.get_paginator('list_services')
            service_arns = []
            for srv_page in srv_paginator.paginate(cluster=cluster_arn):
                service_arns.extend(srv_page.get('serviceArns', []))

            # Verify if oneagent service name exists in service list
            has_oneagent = False
            for service_arn in service_arns:
                if service_arn.split('/')[-1] == service_name:
                    has_oneagent = True
                    break

            if has_oneagent:
                logger.info(f"Dynatrace OneAgent is already installed on cluster {cluster_name}. Skipping.")
            else:
                logger.info(f"Dynatrace OneAgent is missing on cluster {cluster_name}. Auto-provisioning OneAgent service...")
                
                # 3. Provision the OneAgent service as a DAEMON strategy
                ecs_client.create_service(
                    cluster=cluster_arn,
                    serviceName=service_name,
                    taskDefinition=oneagent_task_def_arn,
                    schedulingStrategy='DAEMON',
                    launchType='EC2'
                )
                logger.info(f"Successfully triggered OneAgent deployment on cluster {cluster_name}.")

        return {"status": "success", "message": "ECS clusters scan and deployment checked."}

    except Exception as e:
        logger.error(f"Error during ECS Auto-Observability execution: {str(e)}")
        return {"status": "error", "message": str(e)}
