# OnBoarding Workflow

0. _Main_
    * input company name & region
    * generates:
      * nsg_storage_account_name
      * audit_storage_account_name

    * List Subscriptions for current tennant
    * Create for Cyngular -
      * service principle
      * cyngular resource group
        * audit_storage_account
        * nsg_storage_account
    
    * Loop throgh Subscriptions:
      * run subscription manager on each:
      * assign roles to cyngular service principle in subscription scope:
        * Reader
        * Disk Pool Operator
        * Data Operator for Managed Disks
        * Disk Snapshot Contributor
        * Microsoft Sentinel Reader
      * export activity logs
        * from subscription and region
        * to audit_storage_account

      * create NetworkWatcherRG resource group
      * List resource groups
      * Loop throgh RGs in subscription:
        * if net watcher not in resource group location - configure network_watcher

        * list network interfaces
          * Loop throgh `RGs` in `subscription`:
          * if `net watcher` not in `net interface location` - configure network_watcher

          * if `net interface location` is `northeurope` - create_nsg_flowlog

    
    * Import diagnostic settings
      * audit_storage_account_id
      * region