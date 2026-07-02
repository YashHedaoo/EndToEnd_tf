package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestAwsDynatraceEcsDaemonIntegration(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code to test
		TerraformDir: "../../environments/dev",

		// Variables to pass to the Terraform code using -var options
		Vars: map[string]interface{}{
			"aws_account_id":       "123456789012",
			"dynatrace_url":        "https://abc12345.live.dynatrace.com",
			"dynatrace_paas_token": "dt0c01.test.paas",
			"aws_region":           "us-east-1",
			"cluster_name":         "ecs-oneagent-cluster",
			"instance_type":        "t3.medium",
			"ami_id":               "ami-1234567890abcdef0",
		},
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Since we don't deploy active AWS/Dynatrace connection setup in CI/CD pipeline,
	// we will run Terraform Init and Plan to validate config logic.
	terraform.Init(t, terraformOptions)
	planOutput := terraform.Plan(t, terraformOptions)

	// Assert that the plan contains all expected resources
	assert.Contains(t, planOutput, "module.ecs_oneagent_integration.module.networking.aws_vpc.main")
	assert.Contains(t, planOutput, "module.ecs_oneagent_integration.module.ecs_cluster.aws_ecs_cluster.main")
	assert.Contains(t, planOutput, "module.ecs_oneagent_integration.module.oneagent.aws_ecs_service.oneagent")
	assert.Contains(t, planOutput, "module.ecs_oneagent_integration.module.secrets.aws_secretsmanager_secret.api_url")
	assert.Contains(t, planOutput, "module.ecs_oneagent_integration.module.ecs_capacity.aws_launch_template.ecs")
	assert.Contains(t, planOutput, "module.ecs_oneagent_integration.module.ecs_capacity.aws_autoscaling_group.ecs")
}
