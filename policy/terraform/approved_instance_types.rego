# policy/terraform/approved_instance_types.rego
#
# RDS instance class must be in the approved list.
# Approved classes are cost-conscious sizes suitable for this project.
# Update this list when the project requirements change.
#
# Maps to: modules/database/variables.tf -> instance_class

package terraform.rds.instance_types

import rego.v1

approved_rds_classes := {
	"db.t3.micro",
	"db.t3.small",
	"db.t3.medium",
	"db.t4g.micro",
	"db.t4g.small",
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	instance_class := resource.change.after.instance_class

	not instance_class in approved_rds_classes

	msg := sprintf(
		"[approved_instance_types] %s: RDS instance class '%s' is not approved. Approved classes: %v",
		[resource.address, instance_class, approved_rds_classes],
	)
}
