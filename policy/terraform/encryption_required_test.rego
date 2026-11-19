# policy/terraform/encryption_required_test.rego

package terraform.encryption

import rego.v1

# ── RDS: passing ──────────────────────────────────────────────────────────────

test_rds_encrypted_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {
				"storage_encrypted": true,
				"publicly_accessible": false,
				"instance_class": "db.t3.micro",
			}},
		}],
	}
}

# ── RDS: failing ──────────────────────────────────────────────────────────────

test_rds_unencrypted_denied if {
	msgs := deny with input as {
		"resource_changes": [{
			"address": "module.database.aws_db_instance.this",
			"type": "aws_db_instance",
			"change": {"after": {
				"storage_encrypted": false,
				"publicly_accessible": false,
				"instance_class": "db.t3.micro",
			}},
		}],
	}
	count(msgs) == 1
}

# ── S3: passing — SSE config present with AES256 ──────────────────────────────

test_s3_with_sse_passes if {
	count(deny) == 0 with input as {
		"resource_changes": [
			{
				"address": "module.storage.aws_s3_bucket.this",
				"type": "aws_s3_bucket",
				"change": {
					"after": {"bucket": "my-bucket"},
					"after_unknown": {"id": true},
				},
			},
			{
				"address": "module.storage.aws_s3_bucket_server_side_encryption_configuration.this",
				"type": "aws_s3_bucket_server_side_encryption_configuration",
				"change": {"after": {
					"bucket": "my-bucket",
					"rule": [{"apply_server_side_encryption_by_default": [{"sse_algorithm": "AES256"}]}],
				}},
			},
		],
	}
}
