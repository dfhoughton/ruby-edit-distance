require "edit_distance/version"
require 'pry'

module EditDistance

  class Error < StandardError; end

  class Analyzer
    def initialize scale
      raise Error.new "initialization parameter must be a Scale" unless Scale === scale
      @scale = scale
    end

    # returns the edit distance from s1 to s2
    def distance s1, s2
      analyze( s1, s2 ).distance
    end

    # returns a Cell from which one can retrieve the optimal set of edits from s1 to s2
    def analyze s1, s2
      table( s1, s2 ).final_cell
    end

    # list edits from s1 to s2, where edits are in {:same, :insertion, :deletion, :substitution}
    def edits s1, s2
      chain( s1, s2 ).map(&:edit)
    end

    # list table cells in optimal edit sequence
    def chain s1, s2, include_root=false
      t = table s1, s2
      c = t.final_cell
      chain = []
      while !c.root?
        chain << c
        c = c.parent
      end
      chain << t.root if include_root
      chain.reverse
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

  # home of edit distance algorithm
  class Scale
    def weigh parent, edit, source_offset, destination_offset
      1
    end

    def prepare matrix
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

    # the optimal edit path from the root to this cell
    def path
      @path ||= [].tap do |path|
        path << ( c = self )
        while c = c.parent
          path << c
        end
        path.reverse
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

    def inspect
      "<#{chars.inspect}, #{s} -> #{d}, #{edit}, (#{cost})" + 
      %Q{#{ " #{@hash.inspect}" unless @hash.empty?}} +
      %Q{#{ " #{@list.inspect}" unless @list.empty?}} +
      "#{ ' *' if matrix.final_cell && matrix.final_cell.path.include?(self)}>"
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

  # essentially a string wrapper whose [] method provides access to Char instances
  # rather than single character substrings; it to_s method provides the original string
  class CharSeq
    def initialize s
      @s     = s
      @chars = (0...s.length).map{ |i| Char.new s[i], i, s.length - i - 1 }
    end

    def to_s
      @s
    end

    def [] n
      @chars[n]
    end
  end

  # basically a character instrumented to provide list and hash accessors for metadata
  # and pre and post accessor for the distance of the character from the beginning and end of its string
  class Char
    attr_reader :c, :list, :hash, :pre, :post

    def initialize c, pre, post
      @c    = c
      @pre  = pre
      @post = post
      @list = []
      @hash = {}
    end

    # is the character towards the front of its word?
    def front?
      @pre < @post
    end

    # is the character towards the back of its word?
    def back?
      @post < @pre
    end

    def to_s
      @c
    end

    def == other
      @c == other.c
    end

    def inspect
      @c
    end

  end

  # one-use scratchpad
  class Matrix
    attr_reader :source, :destination, :list, :hash, :root

    def initialize source, destination, scale
      @source      = CharSeq.new source
      @destination = CharSeq.new destination
      @scale       = scale
      @matrix      = []
      @list        = []
      @hash        = {}
      @s_dim       = source.length
      @d_dim       = destination.length
      @matrix      = Array.new @s_dim
      (0..@s_dim).each do |i|
        @matrix[i] = Array.new @d_dim + 1
      end
      @root = Cell.new self, @source, @destination, 0, 0, 0.0
      @matrix[0][0] = root
      @scale.prepare self
      # fill all-insertion and all-deletion cells
      (1..@s_dim).each do |i|
        p = @matrix[i-1][0]
        e = :deletion
        w = p.distance + @scale.weigh( p, e, i, 0 )
        @matrix[i][0] = Cell.new self, @source, @destination, i, 0, w, p, e
      end
      (1..@d_dim).each do |i|
        p = @matrix[0][i-1]
        e = :insertion
        w = p.distance + @scale.weigh( p, e, 0, i )
        @matrix[0][i] = Cell.new self, @source, @destination, 0, i, w, p, e
      end
      # fill matrix
      (1..@s_dim).each do |s|
        (1..@d_dim).each do |d|
          c s, d
        end
      end
    end

    def final_cell
      @matrix[@s_dim][@d_dim]
    end

    def inspect
      %Q{#{source} -> #{destination}: } + 
      %Q{#{ "\n  #{@hash.inspect}\n" unless @hash.empty?}} +
      %Q{#{ "\n  #{@list.inspect}\n" unless @list.empty?}} +
      %Q{[\n#{@matrix.map(&:inspect).map{|i| "  #{i}"}.join ",\n"}\n]}
    end

    def cell s, d
      raise Error.new "dimensions of table are #{@s_dim} x #{@d_dim}" if s < 1 || d < 1 || s > @s_dim || d > @d_dim
      @matrix[s][d]
    end

    protected

    def c s, d
      @matrix[s][d] = begin
        s1 = s - 1; d1 = d - 1
        c3 = @matrix[s1][d1]
        if source[s1] == destination[d1]
          p = c3
          w = c3.distance
          e = :same
        else
          c1 = @matrix[s1][d]
          c2 = @matrix[s][d1]
          w1 = c1.distance + @scale.weigh( c1, :deletion, s, d )
          w2 = c2.distance + @scale.weigh( c2, :insertion, s, d )
          w3 = c3.distance + @scale.weigh( c3, :substitution, s, d )
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
        Cell.new self, @source, @destination, s, d, w, p, e
      end
    end
  end

  module_function

  def analyzer alg
    if Class === alg
      Analyzer.new alg.new
    else
      Analyzer.new alg
    end
  end

  # levenshtein distance analyzer
  def levenshtein
    Analyzer.new Scale.new
  end

  # abbreviated levenshtein
  def lev
    levenshtein
  end
end
