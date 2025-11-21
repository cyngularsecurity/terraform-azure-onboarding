module "onboarding" {
   source  = "cyngularsecurity/onboarding/azure"

   ## required
   main_subscription_id = "<deployment_subscription_id>"
   application_id = "<application_id>"
   client_name    = "<company_name>"
   locations      = ["<location1>", "<location2>"]

   ## false by default
   # allow_function_logging = true
   # caching_enabled = true

   ## true by default
   # enable_audit_logs          = false
   # enable_activity_logs       = false
   # enable_aks_logs            = false
   # enable_audit_events_logs   = false
   # enable_flow_logs           = false
}