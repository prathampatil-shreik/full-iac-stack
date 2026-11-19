# policy/terraform/no_public_s3.rego
#
# Ensures every aws_s3_bucket_public_access_block resource has all four
# public-access settings set to true.
#
# Conftest usage:
#   terraform show -json <planfile> | conftest test - --policy policy/terraform

package terraform.s3.public_access

import rego.v1

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	config := resource.change.after

	not config.block_public_acls == true

	msg := sprintf(
		"[no_public_s3] %s: block_public_acls must be true",
		[resource.address],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	config := resource.change.after

	not config.block_public_policy == true

	msg := sprintf(
		"[no_public_s3] %s: block_public_policy must be true",
		[resource.address],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	config := resource.change.after

	not config.ignore_public_acls == true

	msg := sprintf(
		"[no_public_s3] %s: ignore_public_acls must be true",
		[resource.address],
	)
}

deny contains msg if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_public_access_block"
	config := resource.change.after

	not config.restrict_public_buckets == true

	msg := sprintf(
		"[no_public_s3] %s: restrict_public_buckets must be true",
		[resource.address],
	)
}
