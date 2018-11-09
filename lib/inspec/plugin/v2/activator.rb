module Inspec::Plugin::V2
  Activator = Struct.new(
    :plugin_name,
    :plugin_type,
    :activator_name,
    :'activated?',
    :exception,
    :activation_proc,
    :implementation_class,
    :args,
  ) do
    def initialize(*)
      super
      self[:'activated?'] = false
    end

    def activated?(new_value = nil)
      return self[:'activated?'] if new_value.nil?
      self[:'activated?'] = new_value
    end

    def activate!
      return if activated?
      # We want to capture literally any possible exception here, since we are storing them.
      # rubocop: disable Lint/RescueException
      begin
        impl_class = activation_proc.call(args)
        activated?(true)
        self[:implementation_class] = impl_class
      rescue Exception => ex
        self[:exception] = ex
        Inspec::Log.error "Could not activate #{plugin_type} hook named '#{activator_name}' for plugin #{plugin_name}"
      end
      # rubocop: enable Lint/RescueException
    end
  end
end
