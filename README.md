# OnBoarding Workflow

1. Main
    * input company name & region
    * add account extension
    * create service principle
    * for current mgmt azure subscription
      * create cyngular resource group in client region
        * create audit logs storage account
        * create ngs storage account for nsg flow logs

    * List Subscriptions for current tennant - directory
    
    * Loop throgh Subscriptions:
      * run subscription manager on each:
      * assign roles to cyngular service principle in subscription scope:
        * Reader
        * Disk Pool Operator
        * Data Operator for Managed Disks
        * Disk Snapshot Contributor
        * Microsoft Sentinel Reader
      * export activity logs
        * with a diagnostic settings bicep deployment
        * from subscription and region
        * to audit_storage_account

      * create NetworkWatcherRG resource group
      * List resource groups
      * Loop throgh RGs in subscription:
        * if net watcher not in resource group location - configure (enable) network_watcher

        * list network interfaces / nsgs
          * Loop through `NSGs` in `subscription`:
          * if `net watcher` not in `NSG` - configure network_watcher
          * if NSG location is as client loaction: create flow logs for that NSG / Net Interface
    
      * list all resources in curr subscription and in client location
      * loop through Resources
        * Export diagnostic settings
          * from a resource
          * with a specific type of log settings
          * to audit_storage_account_id

    * write sensitive data to a file, encrypt and send to cyngular
      * option to upload to cyngular key vault