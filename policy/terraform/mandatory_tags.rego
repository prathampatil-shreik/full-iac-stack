# policy/terraform/mandatory_tags.rego
#
# All taggable AWS resources must carry the three mandatory tags:
#   Project, Environment, ManagedBy
#
# These match the common_tags local defined in envs/dev/main.tf and
# envs/prod/main.tf and the merge(var.tags, {...}) pattern in every module.

package terraform.tags

import rego.v1

mandatory_tags := {"Project", "Environment", "ManagedBy"}

# Resource types in this project that carry tags
taggable_types := {
	"aws_vpc",
	"aws_subnet",
	"aws_internet_gateway",
	"aws_nat_gateway",
	"aws_eip",
	"aws_route_table",
	"aws_security_group",
	"aws_lb",
	"aws_lb_target_group",
	"aws_lb_listener",
	"aws_ecs_cluster",
	"aws_ecs_task_definition",
	"aws_ecs_service",
	"aws_iam_role",
	"aws_cloudwatch_log_group",
	"aws_db_instance",
	"aws_db_subnet_group",
	"aws_s3_bucket",
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type in taggable_types
	resource.change.actions != ["delete"]

	tags := object.get(resource.change.after, "tags", {})
	missing := mandatory_tags - {tag | tags[tag]}
	count(missing) > 0

	msg := sprintf(
		"[mandatory_tags] %s: missing required tags: %v",
		[resource.address, missing],
	)
}
