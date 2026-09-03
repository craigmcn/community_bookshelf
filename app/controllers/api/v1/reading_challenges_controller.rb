class Api::V1::ReadingChallengesController < Api::V1::BaseController
  before_action -> { require_scope!("read:reading_challenges") }, only: %i[index]
  before_action -> { require_scope!("write:reading_challenges") }, only: %i[create update]
  before_action :set_reading_challenge, only: %i[update]

  def index
    authorize ReadingChallenge
    # .includes(:user) matters here unlike other index actions in this
    # namespace — current_user.reading_challenges would get each record's
    # :user association back-filled for free via Rails' inverse_of caching,
    # but policy_scope's bare where(user:) doesn't, and #books_finished_count
    # below calls back through :user, so without this it's a real N+1.
    @reading_challenges = policy_scope(ReadingChallenge).includes(:user).order(year: :desc)
  end

  def create
    @reading_challenge = current_user.reading_challenges.build(reading_challenge_params_for_create)
    authorize @reading_challenge

    if @reading_challenge.save
      render :show, status: :created
    else
      render json: {errors: @reading_challenge.errors.full_messages}, status: :unprocessable_content
    end
  end

  def update
    authorize @reading_challenge
    if @reading_challenge.update(reading_challenge_params_for_update)
      render :show
    else
      render json: {errors: @reading_challenge.errors.full_messages}, status: :unprocessable_content
    end
  end

  private

  # Scoped to current_user.reading_challenges rather than a bare find,
  # matching the HTML controller — a non-owner requesting another user's
  # challenge id gets a 404 instead of ever reaching the authorize call.
  def set_reading_challenge
    @reading_challenge = current_user.reading_challenges.find(params.expect(:id))
  end

  def reading_challenge_params_for_create
    params.expect(reading_challenge: [:year, :goal])
  end

  # Year is immutable once a challenge exists — it's part of the record's
  # identity (unique per user/year). Only goal is permitted here so a
  # crafted request can't rewrite it.
  def reading_challenge_params_for_update
    params.expect(reading_challenge: [:goal])
  end
end
