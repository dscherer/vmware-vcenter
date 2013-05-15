# Copyright (C) 2013 VMware, Inc.
Puppet::Type.newtype(:esx_datastore) do
  @doc = "Manage vCenter esx hosts service."

  feature :file_storage, 'the provider handles file based storage (CIFS/NFS)'
  feature :block_storage, 'the provider handles block storage (VMFS)'

  newparam(:name, :namevar => true) do
    desc "ESX host:service name."

    munge do |value|
      @resource[:host], @resource[:datastore] = value.split(':',2)
      # TODO: not sure if this is good assumption.
      @resource[:local_path] = @resource[:datastore]
      value
    end
  end

  ensurable

  newparam(:datastore) do
    desc "The name of the datastore."
  end

  newparam(:host) do
    desc "The ESX host the service is running on."
  end

  newproperty(:type) do
    desc "The datastore type."
    isrequired
    newvalue(:vmfs, :required_features => :block_storage)
    newvalue(:nfs, :required_features => :file_storage)
    newvalue(:cifs, :required_features => :file_storage)
    munge do |value|
      value.upcase
    end
  end

  newparam(:local_path) do
  end

  newparam(:access_mode) do
    desc "Enum - HostMountMode: Defines the access mode of the datastore."
    newvalues("readOnly", "readWrite")
    defaultto("readWrite")
    munge do |value|
      value.to_s
    end
  end

  # CIFS/NFS only properties.
  newproperty(:remote_host, :required_features => :file_storage) do
    desc "Name or IP of remote storage host.  Specify only for file based storage."
  end

  newproperty(:remote_path, :required_features => :file_storage) do
    desc "Path to volume on remote storage host.  Specify only for file based storage."
  end

  # CIFS only parameters.
  newparam(:user_name, :required_features => :file_storage) do
  end

  newparam(:password, :required_features => :file_storage) do
  end

  # VMFS only parameters
  newparam(:lun, :required_features => :block_storage) do
    desc "LUN number of storage volume.  Specify only for block storage."
    munge do |value|
      Integer(value)
    end
  end



  validate do
    if ["NFS", "CIFS"].include? self[:type]
      raise Puppet::Error, "Missing remote_host property" unless self[:remote_host]
      raise Puppet::Error, "Missing remote_path property" unless self[:remote_path]
    elsif self[:type] == "VMFS"
      raise Puppet::Error, "Missing lun property" unless self[:lun]
    end
  end

  autorequire(:vc_host) do
    # autorequire esx host.
    self[:host]
  end
end
