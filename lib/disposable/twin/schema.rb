# Schema::from allows to copy a representer structure. This will create "fresh" inline representers instead
# of inheriting/copying the original classes, making it a replication of the structure, only.
#
# Options allow to customize the copied representer.
#
# +:exclude+: ignore options from original Definition when copying.
class Disposable::Twin::Schema
  def self.from(*args, &block)
    new.from(*args, &block)
  end

  # Builds a new representer (structure only) from source_class.
  def from(source_class, options) # TODO: can we re-use this for all the decorator logic in #validate, etc?
    representer = build_representer(options)

    source_representer = options[:representer_from].call(source_class)

    source_representer.representable_attrs.each do |dfn|
      build_definition!(options, dfn, representer)
    end

    representer
  end

private
  def build_representer(options)
    Class.new(options[:superclass]) do
      include *options[:include]
    end
  end

  def build_definition!(options, source_dfn, representer)
    local_options = source_dfn[options[:options_from]] || {} # e.g. deserializer: {..}.

    new_options   = source_dfn.instance_variable_get(:@options).dup # copy original options.
    exclude!(options, new_options)
    new_options.merge!(local_options)

    from_scalar!(options, source_dfn, new_options, representer) && return unless source_dfn[:extend]
    from_inline!(options, source_dfn, new_options, representer)
  end

  def exclude!(options, dfn_options)
    (options[:exclude_options] || []).each do |excluded|
      dfn_options.delete(excluded)
    end
  end

  def from_scalar!(options, dfn, new_options, representer)
    representer.property(dfn.name, new_options)
  end

  def from_inline!(options, dfn, new_options, representer)
    nested      = dfn[:extend].evaluate(nil) # nested now can be a Decorator, a representer module, a Form, a Twin.
    dfn_options = new_options.merge(extend: from(nested, options))

    representer.property(dfn.name, dfn_options)
  end
end