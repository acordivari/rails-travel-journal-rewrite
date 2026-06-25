class CommentsController < ApplicationController
  before_action :require_login

  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to post_path(@post), notice: "Comment added." }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "new_comment",
            partial: "comments/form",
            locals: { post: @post, comment: @comment }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to post_path(@post), alert: @comment.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    authorize_owner_or_admin(@comment.user)
    return if performed?

    @post = @comment.post
    @comment.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to post_path(@post), notice: "Comment deleted." }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
end
