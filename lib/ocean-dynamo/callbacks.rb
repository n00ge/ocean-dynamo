module OceanDynamo
  class Base

    include ActiveModel::Validations::Callbacks

    define_model_callbacks :initialize, only: :after
    define_model_callbacks :save
    define_model_callbacks :create
    define_model_callbacks :update
    define_model_callbacks :destroy
    define_model_callbacks :commit, only: :after
    define_model_callbacks :touch

  end
end
