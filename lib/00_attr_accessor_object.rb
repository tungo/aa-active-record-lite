class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      get = name.to_sym
      set = "#{name}=".to_sym
      attr = "@#{name}"

      define_method(get) do
        instance_variable_get(attr)
      end

      define_method(set) do |value|
        instance_variable_set(attr, value)
      end
    end
  end
end
