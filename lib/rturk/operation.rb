module RTurk
  class Operation

    class << self

      def default_params
        @default_params ||= {}
      end

      def required_params
        @required_params || []
      end

      def require_params(*args)
        @required_params ||= []
        @required_params.push(*args)
      end

      def operation(op)
        default_params.merge!('Operation' => op)
      end

      def create(opts = {}, &blk)
        hit = self.new(opts, &blk)
        response = hit.request
      end

    end

    ########################
    ### Instance Methods ###
    ########################

    def initialize(opts = {})
      opts.each_pair do |k,v|
        if self.respond_to?("#{k.to_sym}=")
          self.send "#{k}=".to_sym, v
        elsif v.is_a?(Array)
          v.each do |a|
            (self.send k.to_s).send a[0].to_sym, a[1]
          end
        elsif self.respond_to?(k.to_sym)
          self.send k.to_sym, v
        end
      end
      yield(self) if block_given?
      self
    end

    def default_params
      self.class.default_params
    end

    def parse(xml)
      # Override this in your operation if you like
      RTurk::Response.new(xml)
    end
    
    def to_params
      {}# Override to include extra params
    end

    def request
      if self.respond_to?(:validate)
        validate
      end
      check_params
      params = self.default_params
      params = to_params.merge(params)
      parse(RTurk.Request(params))
    end

    def check_params
      self.class.required_params.each do |param|
        if self.respond_to?(param)
          raise MissingParameters, "Parameter '#{param.to_s}' cannot be blank" if self.send(param).nil?
        else
          raise MissingParameters, "The parameter '#{param.to_s}' was required and not available"
        end
      end
    end


  end
end