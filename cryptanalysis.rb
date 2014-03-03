require 'facets'
require 'securerandom'
require_relative 'formatting.rb'
require_relative 'caesar.rb'
require_relative 'words.rb'

class Array

  def letter_frequencies
    Hash[frequency.map { |k,v| [k, (v * 100.0/self.length).round(2)] }]
  end

  def shift_with_codeword codeword
    zip(codeword.chars.cycle).map { |text_char, code_char| text_char.in_cipher_alphabet(code_char) }
  end
  alias_method :vigenere, :shift_with_codeword

  def consecutive_letters
    # http://stackoverflow.com/a/8499054/2954849
    chunk_by_identity.map { |n,a| a.join }
  end

  def double_letters
    consecutive_letters.select { |letters| letters.length == 2 }
  end

  def double_letter_frequencies
    double_letters.frequency
  end
end

class String

  def substitute! new_mapping
    puts "\n\n"
    puts "text"
    @mappings = {} unless mappings
    @mappings = Hash[mappings.merge(new_mapping).sort]
    mappings.each do |ciphertext, plaintext|
      puts "#{ciphertext} -> #{plaintext}"
    end

    puts gsub!(new_mapping.keys[0], new_mapping.values[0])
  end

  def nth_letters n
    words.map { |word| word.chars[n] }
  end

  def nth_letter_frequencies n
    nth_letters(n).frequency.sort_by_value
  end

  def first_letter_frequencies
    nth_letter_frequencies 0
  end

  def second_letter_frequencies
    nth_letter_frequencies 1
  end

  def third_letter_frequencies
    nth_letter_frequencies 2
  end

  def last_letter_frequencies
    nth_letter_frequencies(-1)
  end

  def ngrams n
    each_with_index.map { |_,i| self[i..i+(n-1)] }.select { |letters| letters.length == n }
  end

  def ngram_frequencies n
    ngrams.frequency.sort_by_value
  end

  def bigram_frequencies
    ngram_frequencies 2
  end

  def trigram_frequencies
    ngram_frequencies 3
  end

  def highest_bigram_frequencies n=5
    bigram_frequencies.highest_frequencies(n)
  end

  def highest_trigram_frequencies n=5
    trigram_frequencies.highest_frequencies(n)
  end

  def random_padding n
    SecureRandom.base64(n).delete('/+=').upcase[0, n]
  end

  def columnar_transposition_encrypt key, pad=true
    plaintext = self
    if pad && plaintext.length % key.length != 0
      padding = random_padding(key.length - (plaintext.length % key.length))
      plaintext = plaintext + padding
    end
    transposition = plaintext.scan(/.{1,#{key.length}}/).map { |c| c.split(//) }.transpose.map(&:join)
    sorted_transposition = key.split(//).zip(transposition).sort
    ciphertext = sorted_transposition.map { |key, text| text }.join(" ")
    return ciphertext
  end

  def columnar_transposition_decrypt key
    # key.split(//).map.each_with_index.sort.zip(ciphertext.split(" ")).sort { |x,y| x[0][1] <=> y[0][1] }.map { |x| x[1] }.transpose.join
    ciphertext = self
    ciphertext = ciphertext.split(" ")
    key_ordering = key.split(//).map.each_with_index.sort
    key_ciphertext_mapping = key_ordering.zip(ciphertext)
    ordered_ciphertext = key_ciphertext_mapping.sort { |x,y| x[0][1] <=> y[0][1] }
                                                .map { |x| x[1] }
    plaintext = ordered_ciphertext.transpose.join
    return plaintext
  end
end

class Hash
  def highest_frequencies n=5
    Hash[self.sort_by { |k,v| -v }[0..n-1]]
  end
end
