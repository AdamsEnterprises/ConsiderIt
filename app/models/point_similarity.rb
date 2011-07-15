class PointSimilarity < ActiveRecord::Base
  belongs_to :p1, :class_name => "Point"
  belongs_to :p2, :class_name => "Point"
  belongs_to :option
  belongs_to :user
end
