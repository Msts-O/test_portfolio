# frozen_string_literal: true
# モデル基底クラス
class HomeController < ApplicationController
  def index
    @test = { name: 'test1234' }
  end
end
