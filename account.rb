class Account 
  attr_accessor :id, :name, :balance, :currency, :description, :transactions

  def to_hash
    hash = {}
    instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    hash
  end
end