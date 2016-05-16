module Strongbolt
  class UserGroupsUsersController < ::StrongboltController

    self.model_for_authorization = "Strongbolt::UserGroup"

    def create
      @user_group = UserGroup.find(params[:user_group_id])
      @user = Strongbolt.user_class_constant.find(params[:id])

      @user_group.users << @user unless @user_group.users.include?(@user)

      redirect_to request.referrer || user_group_path(@user_group)
    end

    def destroy
      @user_group = UserGroup.find(params[:user_group_id])
      @user = Strongbolt.user_class_constant.find(params[:id])

      @user_group.users.delete @user

      redirect_to request.referrer || user_group_path(@user_group)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      if @user_group.nil?
        flash[:danger] = "User Group ##{params[:user_group_id]} does not exist"
        redirect_to user_groups_path
      else
        flash[:danger] = "User ##{params[:id]} does not exist"
        redirect_to user_group_path(@user_group)
      end
    end

  end
end
