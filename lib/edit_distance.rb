require "edit_distance/version"

module EditDistance

  class Analyzer
    def initialize proc=nil, &block
      if proc
        if Proc === proc
          @scale = proc
        else
          raise "weigh method expected" unless proc.respond_to?(:weigh)
          @scale = -> ( parent, edit, s, d ) { proc.weigh parent, edit, s, d }
        end
      elsif given_block?
        @scale = block
      else
        raise "no edit weighing algorithm provided"
      end
      raise "weighing algorithm expected to have arity of 4" unless @scale.arity == 4
    end

    # returns the edit distance from s1 to s2
    def distance s1, s2
      analyze( s1, s2 ).distance
    end

    # returns a Cell from which one can retrieve the optimal set of edits from s1 to s2
    def analyze s1, s2
      Matrix.new( s1, s2, @scale ).cell s1.length, s2.length
    end

    # returns a description of the sequence of edits as a list of strings
    def explain s1, s2
      cell = analyze s1, s2
      sequence = [ cell ]
      while !( cell = cell.parent ).root?
        sequence.unshift cell
      end
      sequence.map(&:describe)
    end
  end

  class Cell < Struct.new( :source, :destination, :s, :d, :distance, :parent, :edit )

    def root?
      parent.nil?
    end

    # the cost of the edit represented by this cell
    def cost
      @cost ||= distance - parent.distance unless root?
    end
    
    # characters under consideration
    def chars
      @chars ||= begin
        c1 = source[s-1] unless s == 0
        c2 = destination[d-1] unless d == 0
        [ c1, c2 ]
      end
    end

    # a description of the edit represented
    def describe
      c1, c2 = chars
      d = case edit
      when :same         then "kept #{c1}"
      when :insertion    then "inserted #{c2}"
      when :deletion     then "deleted #{c1}"
      when :substitution then "substituted #{c2} for #{c1}"
      end
      d + " (#{cost})"
    end
  end

  class Matrix
    def initialize source, destination, scale
      @source = source
      @destination = destination
      @scale = scale
      @matrix = []
      root = Cell.new source, destination, 0, 0, 0.0
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
          w = p.distance + @scale.call( p, e, s, d )
        elsif d == 0
          p = cell s - 1, d
          e = :call
          w = p.distance + @scale.call( p, e, s, d )
        else
          s1 = s - 1; d1 = d - 1
          c3 = cell s1, d1
          if @source[s1] == @destination[d1]
            p = c3
            w = c3.distance
            e = :same
          else
            c1 = cell s1, d
            c2 = cell s, d1
            w1 = c1.distance + @scale.call( c1, :deletion, s, d )
            w2 = c2.distance + @scale.call( c2, :insertion, s, d )
            w3 = c3.distance + @scale.call( c3, :substitution, s, d )
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
