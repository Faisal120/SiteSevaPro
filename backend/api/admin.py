from fastapi import APIRouter,Depends

from core.auth import require_roles

from services.admin_service import admin_service
from models.subscription import (

    SubscriptionUpdate,

)

router=APIRouter(

prefix="/api/admin",

tags=["Admin"]

)


@router.get("/dashboard")

async def dashboard(

user=Depends(

require_roles(

"SUPER_ADMIN"

)

),

):

    return await admin_service.dashboard()

@router.get("/contractors")
async def contractors(

    page:int=1,

    limit:int=20,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.contractors(

        page,

        limit,

    )
    

@router.get("/contractors/{contractor_id}")
async def contractor(

    contractor_id:str,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.contractor_details(

        contractor_id

    )
    
@router.put("/contractors/{contractor_id}/suspend")
async def suspend(

    contractor_id:str,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.suspend(

        contractor_id

    )
    
@router.put("/contractors/{contractor_id}/activate")
async def activate(

    contractor_id:str,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.activate(

        contractor_id

    )
    
    
@router.get("/subscriptions")
async def subscriptions(

    page:int=1,

    limit:int=20,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.subscriptions(

        page,

        limit,

    )
    
@router.put("/subscriptions/{company_id}")
async def upgrade(

    company_id:str,

    body:SubscriptionUpdate,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.upgrade_subscription(

        company_id,

        body,

    )
    
@router.put("/subscriptions/{company_id}/expire")
async def expire(

    company_id:str,

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.expire_subscription(

        company_id,

    )
    
@router.get("/analytics")
async def analytics(

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.analytics()

@router.get("/logs")
async def logs(

    user=Depends(

        require_roles(

            "SUPER_ADMIN"

        )

    ),

):

    return await admin_service.logs()