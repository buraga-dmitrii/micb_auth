class Transaction
  attr_accessor :date, :description, :amount

  def to_hash
    hash = {}
    instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    hash
  end

  def to_json(*a)
    self.to_hash.to_json(*a)
  end
end