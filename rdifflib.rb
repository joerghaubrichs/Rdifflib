module Enumerable
  def reduce(init)
    result = init
    each { |item| result = yield(result, item) }
    result
  end
end

class Object
  def nil_or_empty?
    nil? or empty?
  end
end

module Diff

  class SequenceMatcher

    def initialize(a = [''], b = [''], isjunk = nil, byline = false)
      a, b = explode(a), explode(b) unless byline 
      @isjunk = isjunk || Proc.new {}
      set_sequences a, b
    end

    def explode(sequence)
      sequence.is_a?(String) ? sequence.split('') : sequence
    end

    def set_sequences(a, b)
      set_sequence_a a
      set_sequence_b b
    end

    def set_sequence_a(a)
      @a = explode(a)
      @matching_blocks = @opcodes = nil
    end

    def set_sequence_b(b)
      @b = explode(b)
      @matching_blocks = @opcodes = nil
      chain_b
    end

    def chain_b
      @fullbcount = nil
      @b2j     = {}
      pophash  = {}
      junkdict = {}
      
      @b.each_with_index do |elt,idx|
        if @b2j.has_key? elt
          indices = @b2j[elt]
          if @b.length >= 200 and indices.length * 100 > @b.length
            pophash[elt] = 1
            indices.clear
          else
            indices.push idx
          end
        else
          @b2j[elt] = [idx]
        end
      end

      pophash.each_key { |elt| @b2j.delete elt }
      
      unless @isjunk.nil?
        [pophash, @b2j].each do |d|
          d.each_key do |elt|
            if @isjunk.call(elt)
              junkdict[elt] = 1
              d.delete elt
            end
          end
        end
      end

      @isbjunk    = junkdict.method(:has_key?)
      @isbpopular = junkdict.method(:has_key?)
    end


    def find_longest_match(alo, ahi, blo, bhi)
      besti, bestj, bestsize = alo, blo, 0
      j2len = {}
      nothing = []
      (alo..ahi-1).step do |i|
        newj2len = {}
        (@b2j[@a[i]] || []).each do |j|
          next  if j < blo
          break if j >= bhi
          
          k = newj2len[j] = (j2len[j - 1] || 0) + 1
          if k > bestsize
            besti, bestj, bestsize = i - k + 1, j - k + 1, k
          end
        end
        j2len = newj2len
      end
      while (besti > alo) and (bestj > blo) and (not @isbjunk.call(@b[bestj-1])) and (@a[besti-1] == @b[bestj-1]) do
        besti, bestj, bestsize = besti-1, bestj-1, bestsize+1
      end
      while (besti+bestsize < ahi) and (bestj+bestsize < bhi) and (not @isbjunk.call(@b[bestj+bestsize])) and (@a[besti+bestsize] == @b[bestj+bestsize]) do
        bestsize += 1
      end

      while (besti > alo) and (bestj > blo) and (@isbjunk.call(@b[bestj-1])) and (@a[besti-1] == @b[bestj-1]) do
        besti, bestj, bestsize = besti-1, bestj-1, bestsize+1
      end
      while (besti+bestsize < ahi) and (bestj+bestsize < bhi) and (@isbjunk.call(@b[bestj+bestsize])) and (@a[besti+bestsize] == @b[bestj+bestsize]) do
        bestsize = bestsize + 1
      end

      return [besti, bestj, bestsize]
    end

    def get_matching_blocks
      return @matching_blocks unless @matching_blocks.nil_or_empty?

      la, lb = @a.size, @b.size
      queue = [[0, la, 0, lb]]
      matching_blocks = []
      while not queue.empty? do
        alo, ahi, blo, bhi = queue.pop
        i, j, k = x = find_longest_match(alo, ahi, blo, bhi)
        unless k.zero?
          matching_blocks << x
          if alo < i and blo < j
            queue.push  [alo,i,blo,j]
          end
          if i+k < ahi and j+k < bhi
            queue.push [i+k, ahi, j+k, bhi]
          end
        end
      end
      matching_blocks.sort!   

      i1 = j1 = k1 = 0
      non_adjacent = []
      matching_blocks.each do |i2, j2, k2|
        if i1 + k1 == i2 and j1 + k1 == j2
          k1 += k2
        else
          unless k1.zero?
            non_adjacent << [i1, j1, k1]
          end
          i1, j1, k1 = i2, j2, k2
        end
      end
      unless k1.zero?
        non_adjacent << [i1, j1, k1]
      end

      non_adjacent << [la, lb, 0]
      @matching_blocks = non_adjacent
    end


    def ratio
      matches = get_matching_blocks.reduce(0) do |sum, triple|
        sum + triple.last
      end
      Diff.calculate_ratio(matches, @a.size + @b.size)
    end

    def quick_ratio
      if @fullbcount.nil_or_empty?
        @fullbcount = {}
        @b.each do |elt|
          @fullbcount[elt] = (@fullbcount[elt] || 0) + 1
        end
      end
      avail   = {}
      matches = 0
      @a.each do |elt|
        if avail.has_key?(elt)
            numb = avail[elt]
        else
            numb = (@fullbcount[elt] || 0)
        end
        avail[elt] = numb - 1
        if numb > 0
            matches = matches + 1
        end
        #numb       = avail.has_key?(elt) ? avail[elt] : (@fullbcount[elt] || 0)
        #avail[elt] = numb - 1
        #matches   += 1 if numb > 0
      end
      Diff.calculate_ratio(matches, @a.size + @b.size)
    end

    def real_quick_ratio
      size_of_a, size_of_b = @a.size, @b.size
      Diff.calculate_ratio([size_of_a, size_of_b].min, size_of_a + size_of_b)
    end

    protected :chain_b
  end # end class SequenceMatcher

  class << self
    def calculate_ratio(matches, length)
      return 1.0 if length.zero?
      2.0 * matches / length
    end

    def get_close_matches(word, possibilities, n=3, cutoff=0.6)
      raise "n must be > 0: #{n}" unless n > 0
      raise "cutoff must be in (0.0..1.0): #{cutoff}" unless (cutoff >= 0.0) and (cutoff <= 1.0)
      result = []
      sequence_matcher = Diff::SequenceMatcher.new
      sequence_matcher.set_sequence_b word
      possibilities.each do |possibility|
        sequence_matcher.set_sequence_a possibility
        rqr = sequence_matcher.real_quick_ratio
        qr =  sequence_matcher.quick_ratio 
        r = sequence_matcher.ratio 
        #print "#{possibility} #{rqr} #{qr} #{r}\n"
        if (rqr >= cutoff) and (qr >= cutoff) and (r >= cutoff) then
          result.push [r, possibility]
        end
      end
      unless result.nil_or_empty?
        result.sort!
        result = result[-n..-1]
        result.reverse!
      end
      result.map! {|score, x| x }
    end

    def get_best_match(word, possibilities, cutoff=0.6)
      result = []
      sequence_matcher = Diff::SequenceMatcher.new
      sequence_matcher.set_sequence_b word
      possibilities.each do |possibility|
        sequence_matcher.set_sequence_a possibility
        rqr = sequence_matcher.real_quick_ratio
        qr =  sequence_matcher.quick_ratio 
        r = sequence_matcher.ratio 
        #print "#{possibility} #{rqr} #{qr} #{r}\n"
        if (rqr >= cutoff) and (qr >= cutoff) and (r >= cutoff) then
          result.push [r, possibility]
        end
      end
      return result.max[1]
    end

    def count_leading(line, ch)
      count, size = 0, line.size
      count += 1 while count < size and line[count].chr == ch
      count
    end
  end
end

