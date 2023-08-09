# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

require "oaken/version"

module Oaken
  class Error < StandardError; end

  module Stored; end
  class Stored::Abstract
    def initialize(type)
      @type = type
    end

    def update(id, **attributes)
      self.class.define_method(id) { find(id) }
    end
  end

  class Stored::Memory < Stored::Abstract
    def find(id)
      objects.fetch(id)
    end

    def update(id, **attributes)
      super
      objects[id] = @type.new(**attributes)
    end

    private def objects
      @objects ||= {}
    end
  end

  class Stored::ActiveRecord < Stored::Abstract
    def find(id)
      @type.find(id.hash)
    end

    def update(id, **attributes)
      super

      if record = @type.find_by(id: id.hash)
        record.update!(**attributes)
      else
        @type.create!(id: id.hash, **attributes)
      end
    end
  end

  module Data
    extend self

    class Provider < Struct.new(:data, :provider)
      def register(type)
        stored = provider.new(type)
        data.define_method(type.to_s.underscore.tr("/", "_").pluralize) { stored }
      end
    end

    def self.provider(name, provider)
      define_singleton_method(name) { (@providers ||= {})[name] ||= Provider.new(self, provider) }
    end

    provider :memory, Stored::Memory
    provider :records, Stored::ActiveRecord

    def self.load_from(directory)
      Dir.glob("#{directory}/**/*").sort.each do |file|
        Oaken::Data.class_eval File.read(file)
      end
    end
  end
end
