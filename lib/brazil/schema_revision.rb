module Brazil
  class SchemaRevision
    include Comparable
    
    TYPE_MAJOR = :major
    TYPE_MINOR = :minor
    TYPE_PATCH = :patch

    def initialize(major, minor, patch, created = nil, description = nil)
      @major = major.to_i if major
      @minor = minor.to_i if minor
      @patch = patch.to_i if patch
      
      @created = created
      @description = description
    end

    def self.from_string(version)
      if version.respond_to?(:split)
        major, minor, patch = version.split('_')
        SchemaRevision.new(major, minor, patch)
      else
        nil
      end
    end

    def next version_type = TYPE_MINOR
      numbers = to_a
      
      case version_type
        when TYPE_MAJOR
          numbers[0] += 1
        when TYPE_MINOR
          numbers[1] += 1
        when TYPE_PATCH
          numbers[2] += 1
      end
        
      SchemaRevision.new(numbers[0], numbers[1], numbers[2])
    end

    def prev
      numbers = to_a
      numbers[-1] -= 1 if numbers[-1] > 0
      SchemaRevision.new(numbers[0], numbers[1], numbers[2])
    end

    def to_s
      to_a.join('_')
    end

    def <=>(other_version)
      to_a <=> other_version.to_a
    end

    def include?(other_version)
      (other_version.to_a.slice(0, to_a.length) <=> to_a) == 0
    end

    def to_a
      [@major, @minor, @patch].compact
    end

    def major
      @major.to_i
    end

    def minor
      @minor.to_i
    end

    def patch
      @patch.to_i
    end

    def created
      @created
    end

    def description
      @description
    end

  end
end
