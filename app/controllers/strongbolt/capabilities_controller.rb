module Strongbolt
  class CapabilitiesController < ::StrongboltController
    def index
      @capabilities = Capability.all
    end

    def show
      @capability = Capability.find params[:id]
    end

    def create
      @capability = Capability.where(capability_params).first_or_create

      # If we have a role id, we add the capability to the role
      if params[:role_id].present?
        @role = Role.find params[:role_id]
        @role.capabilities << @capability

        respond_to do |format|
          format.html { redirect_to role_path(@role) }
          format.json { head :ok }
        end
      else
        redirect_to capabilities_path
      end
    rescue ActionController::ParameterMissing => e
      flash[:danger] = "Permission could not be created: ERROR #{e}"
      redirect_to capabilities_path
    end

    def destroy
      # If we're passed a role id
      if params[:role_id].present?
        @role = Role.find params[:role_id]

        conditions = if params[:id].present?
                       { id: params[:id] }
                     else
                       capability_params
                     end

        @capability = @role.capabilities.find_by(conditions)
        @role.capabilities.delete @capability

        respond_to do |format|
          format.html { redirect_to role_path(@role) }
          format.json { head :ok }
        end
      else
        @capability = Capability.find params[:id]
        @capability.destroy

        redirect_to capabilities_path
      end
    rescue ActiveRecord::DeleteRestrictionError
      flash[:danger] = 'Permission has roles using it, delete relationships before deleting it'

      redirect_to capability_path(@capability)
    end

    private

    def capability_params
      params.require(:capability).permit(:model, :action,
                                         :require_ownership, :require_tenant_access)
    end
  end
end
