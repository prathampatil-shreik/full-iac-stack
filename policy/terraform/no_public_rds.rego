# policy/terraform/no_public_rds.rego
#
# aws_db_instance.publicly_accessible must be false.
# Our database module already sets this to false; this policy enforces it
# cannot be overridden to true in any plan.

package terraform.rds.public_access

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_db_instance"
	resource.change.after.publicly_accessible == true

	msg := sprintf(
		"[no_public_rds] %s: RDS instance must not be publicly accessible (publicly_accessible = true)",
		[resource.address],
	)
}
