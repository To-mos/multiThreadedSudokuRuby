 #pseudo code
#let each cell keep track of it's self and remove pre filled cells
#have that cell update its own values as we sweep over the board and update them
#randomly slam the board with numbers per cell until it finds the right combination
#
#pull in the multi-threading library
require 'thread'

class Sudoku
  def initialize(board_string)
    @board_done = false
    #clean the board right off the bat
    @board_array = parse_board(board_string)
    #generate the sizes for index calculations
    @board_array_size = @board_array.size
    #sudoku boards are perfect squares of themselves
    #soo a sub cell is a sqrt of the parent
    @sub_cell_size = Math.sqrt(@board_array_size)
  end

  def parse_board(unparsed_string)
    array1 = unparsed_string.scan(/.{1}/).to_a
    array1.map! do |val|
      typecast_val = val.to_i

      #assign the appropriate values to the cell object
      #then add it to the board array
      typecast_val>0 ? Cell.new(typecast_val, true) : Cell.new(nil, false)
    end
    array1.each_slice(9).to_a
  end

  def subgrid_has_value?(row_index, col_index, value)
      first_row_index = row_index - (row_index % @sub_cell_size)
      first_col_index = col_index - (col_index % @sub_cell_size)
      last_row_index  = first_row_index + @sub_cell_size - 1
      last_col_index  = first_col_index + @sub_cell_size - 1

     #first_row_index.to_i.upto(last_row_index) do |y|
     #  first_col_index.to_i.upto(last_col_index) do |x|
     #    #p "the current search is: #{@board_array[x][y].value}"
     #    return true if @board_array[x][y].value == value
     #  end
     #end
     @board_array[first_row_index..last_row_index].each do |row|
        row[first_col_index..last_col_index].each do |cell|
          return true if cell.value == value
        end
      end
      false
  end

  def solve
    cell_index, cell = cell_check(@cell_index,"origin")
    while !cell.nil?
      cell_value = cell.increase
      unless cell_value == false
        if allowed_num?(cell_index, cell_value)
          cell.increase!
          #p cell.value
          cell_index, cell = cell_check(cell_index,"next")
        else
          cell.increase!
        end
      else
        cell.clear!
        cell_index, cell = cell_check(cell_index,"prev")
      end
    end
    @board_done = true
  end

  def solved?
    @board_done
  end

  def cell_check(cell_index, method)
    case method
    when "origin"
        #p (@board_array_size*@board_array_size-1)
        (0..(@board_array_size*@board_array_size-1)).each do |index|
          return index, cell_board_pos(index) if !cell_board_pos(index).prefilled?
        end
        return nil
    when "next" # run though the cell numbers then return a non prefilled cell index
        (cell_index+1..(@board_array_size*@board_array_size-1)).each do |index|
          return index, cell_board_pos(index) if !cell_board_pos(index).prefilled?
        end
        return nil, nil
    when "prev"
        (0..cell_index-1).reverse_each do |index|
          return index, cell_board_pos(index) if !cell_board_pos(index).prefilled?
        end
        return nil, nil
    end
  end

  def cell_board_pos(cell_index)
    @board_array[cell_index / @board_array_size.to_i][cell_index % @board_array_size.to_i]
  end

  #Constraints for brute force method
  def allowed_num?(shift, value)
    #Create a diagonal search pattern
    row_index = shift / @board_array_size.to_i
    col_index = shift % @board_array_size.to_i

    #Check for value in row
    (0..@board_array_size-1).each do |colval|
      return false if @board_array[row_index][colval].value == value
    end
    #Check for value in col
    (0..@board_array_size-1).each do |rowval|
      return false if @board_array[rowval][col_index].value == value
    end
    #Check the subgrid
    return false if subgrid_has_value?(row_index,col_index,value)
      true
  end

  def board
    output = "+---+---+---+---+---+---+---+---+---+\n"
    0.upto(@board_array_size-1) do |y|
        0.upto(@board_array_size-1) do |x|
          output += (x == 0) ? "| #{@board_array[y][x].append_check} |" : " #{@board_array[y][x].append_check} |" 
        end
        output += "\n+---+---+---+---+---+---+---+---+---+\n"
    end
    output
  end

  def output
    print "\e[H"
    print board
    $stdout.flush
  end
end

class Cell
  attr_accessor :value

  def initialize(value, prefilled = false)
    @value = value; @prefilled = prefilled
  end

  def increase
      blank? ? 1 : (@value == 9 ? false : @value.next)
  end

  def increase!
    @value = self.increase
    #p "incriment #{@value}"
  end

  def clear!
    @value = nil
  end

  def blank?
    @value.nil? ? true : false
  end

  def prefilled?
    @prefilled
  end

  def append_check
    blank? ? '-' : @value.to_s
  end
end

#clear terminal
print "\e[2J"
print "\e[H"
current_line = 0
compiled_output = ""
File.open('sample.unsolved.txt').each_line do |line|
  puts "SOLVING board #{current_line}"
  game = Sudoku.new(line)
  solver_thread=Thread.new {game.solve}
  #multi threading the display system
  display_thread=Thread.new do
    until game.solved? == true
      game.output
    end
    compiled_output += "\nBOARD: \##{current_line}\n#{game.board}"
    game.output
    puts "SOLVED board: #{current_line}"
  end

  #build a new thread
  solver_thread.join
  display_thread.join
  
  current_line+=1
end
puts compiled_output
