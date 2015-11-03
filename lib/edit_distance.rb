require "edit_distance/version"

module EditDistance

  class Error < StandardError; end

  class Analyzer
    def initialize proc=nil, &block
      if proc
        if Proc === proc
          @scale = proc
        else
          raise "weigh method expected" unless proc.respond_to?(:weigh)
          raise Error.new "weigh method expected to have arity of 4" unless proc.method(:weigh).arity == 4
          @scale = -> ( parent, edit, s, d ) { proc.weigh parent, edit, s, d }
        end
      elsif block_given?
        @scale = block
      else
        raise Error.new "no edit weighing algorithm provided"
      end
      raise Error.new "weighing algorithm expected to have arity of 4" unless @scale.arity == 4
    end

    # returns the edit distance from s1 to s2
    def distance s1, s2
      analyze( s1, s2 ).distance
    end

    # returns a Cell from which one can retrieve the optimal set of edits from s1 to s2
    def analyze s1, s2
      table( s1, s2 ).cell s1.length, s2.length
    end

    # produces the table used to calculate edit distances
    def table s1, s2
      Matrix.new( s1, s2, @scale )
    end

    # returns a description of the sequence of edits as a list of strings
    def explain s1, s2
      analyze( s1, s2 ).explain
    end
  end

  # element of a Matrix
  class Cell < Struct.new( :matrix, :source, :destination, :s, :d, :distance, :parent, :edit )

    # is this the pre-edit cell?
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

    # explain all the edits up to and including the edit in the current cell
    def explain
      cell = self
      sequence = [ cell ]
      while !( cell = cell.parent ).root?
        sequence.unshift cell
      end
      sequence.map(&:describe)
    end

    # a handle on the matrix list for stashing listable stuff
    def list
      @matrix.list
    end

    # a handle on the matrix hash for stashing mappable stuff
    def hash
      @matrix.hash
    end

  end

  # one-use scratchpad
  class Matrix
    def initialize source, destination, scale
      @source      = source
      @destination = destination
      @scale       = scale
      @matrix      = []
      @list        = []
      @hash        = {}
      @s_dim       = source.length
      @d_dim       = destination.length
      root = Cell.new self, source, destination, 0, 0, 0.0
      @matrix[0] = [ root ]
      source.length.times do |i|
        @matrix << []
      end
    end

    def list
      @list
    end

    def hash
      @hash
    end

    def cell s, d
      raise Error.new "dimensions of table are #{@s_dim} x #{@d_dim}" if s < 0 || d < 0 || s > @s_dim || d > @d_dim
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
        Cell.new @matrix, @source, @destination, s, d, w, p, e
      end
    end
  end

  module_function

  # levenshtein distance analyzer
  def levenshtein
    Analyzer.new -> (_,_,_,_) {1}
  end

  # abbreviated levenshtein
  def lev
    levenshtein
  end
end
