require "edit_distance/version"

module EditDistance

  class Analyzer
    def initialize proc=nil, &block
      if proc
        if Proc === proc
          @scale = proc
        else
          @scale = -> (parent,edit,c,d) { proc.weigh parent, edit, c, d }
        end
      elsif given_block?
        @scale = block
      else
        raise "no edit weighing algorithm provided"
      end
      raise "weighing algorithm expected to have arity of 4" unless block.arity == 4
    end

    # returns the edit distance from s1 to s2
    def distance s1, s2
      analyze( s1, s2 ).distance
    end

    # returns a Cell from which one can retrieve the optimal set of edits from s1 to s2
    def analyze s1, s2
      Matrix.new( s1, s2, @scale ).cell s1.length, s2.length
    end
  end

  class Scale
    def weigh parent, edit, s, d
      raise NotImplementedError
    end
  end

  class Cell < Struct.new( :source, :destination, :s, :d, :distance, :parent, :edit )
    def describe
    end
  end

  class Matrix
    def initialize source, destination, scale
      @source = source
      @destination = destination
      @scale = scale
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
          e = :deletion
          w = @scale.weigh p, e, s, d
        elsif d == 0
          p = cell s - 1, d
          e = :insertion
          w = @scale.weigh p, e, s, d
        else
          c3 = cell s - 1, d - 1
          if @source[s] == @destination[d]
            p = c3
            w = c3.distance
            e = Edit::SAME
          else
            c1 = cell s - 1, d
            c2 = cell s, d - 1
            w1 = @scale.weigh c1, :deletion, s, d
            w2 = @scale.weigh c2, :insertion, s, d
            w3 = @scale.weigh c3, :substitution, s, d
            if w1 < w3
              if w1 < w2
                p = c1
                w = w1
                e = :deletion
              else
                p = c2
                w = w2
                e = :insertion
              end
            elsif w2 < w3
              p = c2
              w = w2
              e = :insertion
            else
              p = c3
              w = w3
              e = :substitution
            end
          end
        end
        Cell.new @source, @destination, s, d, w, p, e
      end
    end
  end
end
