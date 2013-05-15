# Copyright (C) 2013 VMware, Inc.
provider_path = Pathname.new(__FILE__).parent.parent
require File.join(provider_path, 'vcenter')

Puppet::Type.type(:esx_datastore).provide(:block, :parent => Puppet::Provider::Vcenter) do
  @doc = "Manages vCenter VMFS (block) datastores."

  has_feature :block_storage

  confine :feature => :block_storage

  def create
    host.configManager.storageSystem.RescanAllHba()
    host_scsi_disks = host.configManager.datastoreSystem.QueryAvailableDisksForVmfs()
    host_scsi_disks.each do |host_scsi_disk|
      if scsi_lun(host_scsi_disk.uuid) == resource[:lun]
        vmfs_ds_options = host.configManager.datastoreSystem.QueryVmfsDatastoreCreateOptions(
          :devicePath => host_scsi_disk.devicePath)
        # Use the 1st (only?) spec provided by the QueryVmfsDatastoreCreateOptions call
        spec = vmfs_ds_options[0].spec
        # set the name of the soon to be created datastore
        spec.vmfs[:volumeName] = resource[:datastore]
        # create the datastore
        host.configManager.datastoreSystem.CreateVmfsDatastore(:spec => spec)
      end
    end
  end

  def destroy
    host.configManager.datastoreSystem.RemoveDatastore(:datastore => @datastore)
  end

  def type
    @datastore.summary.type
  end

  def type=(value)
    warn "Can not change resource type."
  end

  def exists?
    @datastore = host.datastore.find{|d|d.name==resource[:datastore]}
  end

  private

  def scsi_lun (uuid)
    @host.configManager.storageSystem.storageDeviceInfo.scsiTopology.adapter.each do |adapter|
      adapter.target.each do |target|
        target.lun.each do |lun_obj|
          # This is a hack to work around a RbVmomi bug where the scsiLun property is returned
          #   as a blank object rather than a string
          return lun_obj.lun if lun_obj.key =~ /#{uuid}/
        end
      end
    end
    nil
  end

  def host
    @host ||= vim.searchIndex.FindByDnsName(:dnsName => resource[:host], :vmSearch => false)
  end
end
