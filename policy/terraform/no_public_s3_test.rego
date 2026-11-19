# policy/terraform/no_public_s3_test.rego

package terraform.s3.public_access

import rego.v1

# ── Passing ───────────────────────────────────────────────────────────────────

test_all_public_access_blocked_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.storage.aws_s3_bucket_public_access_block.this",
			"type": "aws_s3_bucket_public_access_block",
			"change": {"after": {
				"block_public_acls": true,
				"block_public_policy": true,
				"ignore_public_acls": true,
				"restrict_public_buckets": true,
			}},
		}],
	}
}

# ── Failing ───────────────────────────────────────────────────────────────────

test_block_public_acls_false_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.storage.aws_s3_bucket_public_access_block.this",
			"type": "aws_s3_bucket_public_access_block",
			"change": {"after": {
				"block_public_acls": false,
				"block_public_policy": true,
				"ignore_public_acls": true,
				"restrict_public_buckets": true,
			}},
		}],
	}
	count(msgs) == 1
}

test_all_false_produces_four_denials if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.storage.aws_s3_bucket_public_access_block.this",
			"type": "aws_s3_bucket_public_access_block",
			"change": {"after": {
				"block_public_acls": false,
				"block_public_policy": false,
				"ignore_public_acls": false,
				"restrict_public_buckets": false,
			}},
		}],
	}
	count(msgs) == 4
}
