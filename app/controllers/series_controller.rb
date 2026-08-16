class SeriesController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  before_action :set_series, only: %i[show edit update destroy]

  def index
    @series = policy_scope(Series).includes(:books).order(:name)
  end

  def show
    authorize @series
    @books = @series.books.order(Arel.sql("series_position NULLS LAST, title"))
  end

  def new
    @series = Series.new
    authorize @series
  end

  def edit
    authorize @series
  end

  def create
    @series = Series.new(series_params)
    authorize @series

    if @series.save
      redirect_to @series, notice: "Series was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @series
    if @series.update(series_params)
      redirect_to @series, notice: "Series was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @series
    @series.destroy!
    redirect_to series_index_path, notice: "Series was successfully destroyed.", status: :see_other
  end

  private

  def set_series
    @series = Series.find(params.expect(:id))
  end

  def series_params
    params.expect(series: [:name])
  end
end
