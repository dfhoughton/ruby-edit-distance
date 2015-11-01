require "edit_distance/version"

module EditDistance

  class Analyzer
    include Virtus.model

    attribute :scale, Scale

    # returns the edit distance from s1 to s2
    def distance s1, s2
      analyze( s1, s2 ).distance
    end

    # returns a Cell from which one can retrieve the optimal set of edits from s1 to s2
    def analyze s1, s2
      Matrix.new( source: s1, destination: s2, scale: scale ).cell s1.length, s2.length
    end
  end

  # a set of constants
  class Edit
    SAME = Edit.new
    INSERTION = Edit.new
    DELETION = Edit.new
    SUBSTITUTION = Edit.new
  end

  class Scale
    def weigh parent, edit, s, d
      raise NotImplementedError
    end
  end

  class Cell < Struct.new( :source, :destination, :s, :d, :distance, :parent, :edit )
  end

  class Matrix
    include Virtus.model

    attribute :source, String
    attribute :destination, String
    attribute :scale, Scale

    def initialize *args
      super
      @matrix = []
      root = Cell.new source, destination, 0, 0, 0
      m0 = @matrix[0] = [ root ]
      source.length.times do |i|
        @matrix << []
      end
    end

    def cell s, d
      @matrix[s][d] ||= begin
        if s == 0
          p = cell s, d - 1
          e = Edit::INSERTION
          w = scale.weigh p, e, s, d
        elsif d == 0
          p = cell s - 1, d
          e = Edit::DELETION
          w = scale.weigh p, e, s, d
        else
          c3 = cell s - 1, d - 1
          if source[s] == destination[d]
            p = c3
            w = c3.distance
            e = Edit::SAME
          else
            c1 = cell s - 1, d
            c2 = cell s, d - 1
            w1 = scale.weigh c1, Edit::INSERTION, s, d
            w2 = scale.weigh c2, Edit::DELETION, s, d
            w3 = scale.weigh c3, Edit::SUBSTITUTION, s, d
            if w1 < w3
              if w1 < w2
                p = c1
                w = w1
                e = Edit::INSERTION
              else
                p = c2
                w = w2
                e = Edit::DELETION
              end
            elsif w2 < w3
              p = c2
              w = w2
              e = Edit::DELETION
            else
              p = c3
              w = w3
              e = Edit::SUBSTITUTION
            end
          end
        end
        Cell.new source, destination, s, d, w, p, e
      end
    end
  end
end
