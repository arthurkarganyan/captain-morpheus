# Backpropagation Algorithm in the Ruby Programming Language

# The Clever Algorithms Project: http://www.CleverAlgorithms.com
# (c) Copyright 2010 Jason Brownlee. Some Rights Reserved.
# This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 2.5 Australia License.

class NetTrainer
  attr_reader :in_data
  attr_writer :learning_rate
  attr_writer :num_hidden_nodes
  attr_writer :iterations

  def initialize(in_data)
    @in_data = in_data

    validol(in_data)
  end

  def random_vector(minmax)
    Array.new(minmax.size) do |i|
      minmax[i][0] + ((minmax[i][1] - minmax[i][0]) * rand)
    end
  end

  def initialize_weights(num_weights)
    minmax = Array.new(num_weights) { [-rand, rand] }
    random_vector(minmax)
  end

  def self.activate(weights, vector)
    sum = weights[weights.size - 1] * 1.0
    vector.each_with_index do |input, i|
      sum += weights[i] * input
    end
    sum
  end

  def self.transfer(activation)
    1.0 / (1.0 + Math.exp(-activation))
  end

  def transfer_derivative(output)
    output * (1.0 - output)
  end

  def self.forward_propagate(net, vector)
    net.each_with_index do |layer, i|
      input = i == 0 ? vector : Array.new(net[i - 1].size) { |k| net[i - 1][k][:output] }
      layer.each do |neuron|
        neuron[:activation] = activate(neuron[:weights], input)
        neuron[:output] = transfer(neuron[:activation])
      end
    end
    net.last[0][:output]
  end

  def backward_propagate_error(network, expected_output)
    network.size.times do |n|
      index = network.size - 1 - n
      if index == network.size - 1
        neuron = network[index][0] # assume one node in output layer
        error = (expected_output - neuron[:output])
        neuron[:delta] = error * transfer_derivative(neuron[:output])
      else
        network[index].each_with_index do |neuron, k|
          sum = 0.0
          # only sum errors weighted by connection to the current k'th neuron
          network[index + 1].each do |next_neuron|
            sum += (next_neuron[:weights][k] * next_neuron[:delta])
          end
          neuron[:delta] = sum * transfer_derivative(neuron[:output])
        end
      end
    end
  end

  def calculate_error_derivatives_for_weights(net, vector)
    net.each_with_index do |layer, i|
      input = i == 0 ? vector : Array.new(net[i - 1].size) { |k| net[i - 1][k][:output] }
      layer.each do |neuron|
        input.each_with_index do |signal, j|
          neuron[:deriv][j] += neuron[:delta] * signal
        end
        neuron[:deriv][-1] += neuron[:delta] * 1.0
      end
    end
  end

  def update_weights(network, learning_rate, mom = 0.8)
    network.each do |layer|
      layer.each do |neuron|
        neuron[:weights].each_with_index do |_w, j|
          delta = (learning_rate * neuron[:deriv][j]) + (neuron[:last_delta][j] * mom)
          neuron[:weights][j] += delta
          neuron[:last_delta][j] = delta
          neuron[:deriv][j] = 0.0
        end
      end
    end
  end

  def correct_output?(output, expected)
    expected.is_a?(Range) && expected.include?(output.round) || output.round == expected
  end

  def train_network(network, domain, iterations, learning_rate)
    correct = 0
    last_correctness_pc = 0.0
    last_correctness_pc_count = 0
    correctness_pc = 0.0
    iterations.times do |epoch|
      domain.each do |pattern|
        vector = pattern.first
        expected = pattern.last
        output = self.class.forward_propagate(network, vector)
        correct += 1 if correct_output?(output, expected)
        expected = 0 if expected == (0...0.5)
        backward_propagate_error(network, expected)
        calculate_error_derivatives_for_weights(network, vector)
      end
      update_weights(network, learning_rate)
      if (epoch + 1).modulo(100) == 0
        correctness_pc = (correct.to_f/(100 * domain.size))

        correctness_pc_str = correctness_pc.pc_traffic_light(1.0, 0.95)
        # puts "> epoch=#{epoch + 1}, Correct=#{correct}/#{100 * domain.size} #{correctness_pc_str}"
        print "#{correctness_pc_str} "

        return correctness_pc if correctness_pc == 1.0
        if correctness_pc == last_correctness_pc
          last_correctness_pc_count += 1
        else
          last_correctness_pc = 0.0
          last_correctness_pc_count = 0
          last_correctness_pc = correctness_pc
        end
        return correctness_pc if last_correctness_pc_count == 10 && correctness_pc > 0.95

        correct = 0
      end
    end
    correctness_pc
  end

  def test_network(network, domain)
    correct = 0
    domain.each do |pattern|
      input_vector = pattern.first
      output = self.class.forward_propagate(network, input_vector)
      correct += 1 if correct_output?(output, pattern.last)
    end
    puts "\nFinished test with a score of #{correct}/#{domain.length}: #{(correct.to_f/domain.length).pc}"
    correct
  end

  def create_neuron(inputs)
    {weights: initialize_weights(inputs + 1),
     last_delta: Array.new(inputs + 1) { 0.0 },
     deriv: Array.new(inputs + 1) { 0.0 }}
  end

  def execute(domain, iterations, num_nodes, learning_rate)
    network = nil
    loop do
      num_nodes = [3,4].sample
      network = []
      network << Array.new(num_nodes) { create_neuron(inputs) }
      # network << Array.new(num_nodes) { create_neuron(inputs) } if rand(2) % 2 == 0
      network << Array.new(1) { create_neuron(network.last.size) }
      puts "Topology: #{inputs} #{network.inject('') { |m, i| m + "#{i.size} " }}"
      break if train_network(network, domain, iterations, learning_rate) > 0.95
      puts "Training failed. Retraining!"
    end
    test_network(network, domain)
    network
  end

  def validol(in_data)
    if in_data.map(&:size).uniq.size != 1
      fail("inputs are not the same size")
    end
  end

  def learning_rate
    @learning_rate
  end

  def num_hidden_nodes
    @num_hidden_nodes
  end

  def iterations
    @iterations
  end

  def inputs
    @inputs ||= in_data.first.first.size
  end

  def generate
    net = nil
    time = Benchmark.measure do
      net = execute(in_data, iterations, num_hidden_nodes, learning_rate)
    end.real
    puts "Took #{time.round(1)} seconds"
    net
    # p test_network(network, [[30.0, 30.0, 1]], 2)
  end
end
