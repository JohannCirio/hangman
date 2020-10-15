
require 'pry'
dicio = ['banana', 'tilapia', 'ivo']



def search_letter(word, letter)
  starting_point = 0 
  letter_occurrences = [] 
  stop = false
  until stop == true
    result = word.index(letter, starting_point)
    if result.nil?
      break
    else
      letter_occurrences.push(result)
      starting_point = result += 1
    end
  end
  return letter_occurrences
end

binding.pry

