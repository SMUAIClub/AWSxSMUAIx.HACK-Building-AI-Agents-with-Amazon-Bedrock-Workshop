resource "aws_bedrockagentcore_memory" "this" {
  name                  = "${replace(var.name_prefix, "-", "_")}_memory"
  description           = "Conversation memory for the virtual meteorologist agent"
  event_expiry_duration = 30
}
