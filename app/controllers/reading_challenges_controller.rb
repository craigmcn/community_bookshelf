class ReadingChallengesController < ApplicationController
  before_action :set_reading_challenge, only: %i[edit update]

  def index
    authorize ReadingChallenge
    @reading_challenges = current_user.reading_challenges.order(year: :desc)
  end

  def new
    @reading_challenge = current_user.reading_challenges.build(year: Date.current.year)
  end

  def edit
  end

  def create
    @reading_challenge = current_user.reading_challenges.build(reading_challenge_params)
    authorize @reading_challenge

    if @reading_challenge.save
      redirect_to reading_challenges_path, notice: "Reading challenge was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @reading_challenge
    if @reading_challenge.update(reading_challenge_params)
      redirect_to reading_challenges_path, notice: "Reading challenge was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Scoped to current_user.reading_challenges rather than a bare find, so a
  # non-owner requesting another user's challenge id gets a 404 instead of
  # ever reaching the authorize call.
  def set_reading_challenge
    @reading_challenge = current_user.reading_challenges.find(params.expect(:id))
  end

  def reading_challenge_params
    params.expect(reading_challenge: [:year, :goal])
  end
end
