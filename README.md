# OnBoarding Workflow

1. Main
    * input `company name` & `region`
    * add account extension
    * create `Service Principle`
      * get SP object id from app id
    * for current (mgmt / default) azure subscription
      * create `CyngularRG resource group` in client region
        * create `audit logs` storage account
        * create nsg storage account for `nsg flow logs`
      * get storage accounts `connection strings`

    * List Subscriptions for logged in tennant / directory
    
    * Loop throgh Subscriptions:
      * per subscription:
      * assign roles to cyngular service principle in subscription scope:
        * Reader
        * Disk Pool Operator
        * Data Operator for Managed Disks
        * Disk Snapshot Contributor
        * Microsoft Sentinel Reader
      * export activity logs
        * with a diagnostic settings bicep deployment
        * from subscription and client region
        * to audit_storage_account

      * create NetworkWatcherRG resource group
      * List resource groups
      * per RG:
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