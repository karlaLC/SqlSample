USE [*****]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Karla Lopez
-- Create date: April 5, 2018
-- Description:	Timeline Feed Display
-- =============================================
ALTER PROCEDURE [dbo].[Timelines_TimelineFeedUserJoin_SelectByUserBaseId]
	-- Add the parameters for the stored procedure here
	@currentUserBaseId int 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if(OBJECT_ID('tempdb..#timelineFeed') is not null) drop table #timelineFeed
    -- Insert statements for procedure here
 
	select top 20 * 
	into #timelineFeed
	from (

		select
			'Status' as TimelineType,
			tf.Id,
			tf.FeedContent, 
			tf.IsPublic,
			tf.IsSubscriptionOnly,
			tf.CreatedDate,
			up.UserBaseId,
			CONCAT (up.FirstName,' ',up.MiddleName,' ',up.LastName) as UserName,
			up.FirstName,
			up.MiddleName,
			up.LastName,
			up.AvatarURL,
			rel.FollowingUserId,
			cast (case when @currentUserBaseId = tf.CreatedById then 1 else 0 end as bit) as TimelineOwner,
			(select rel.AppRoleId from Users_UserBase as ub2 join Users_UserBaseAppRoleRel as rel on rel.UserBaseId=ub2.Id where ub2.Id=@currentUserBaseId ) as AppRoleId,
			'' as ExtraFeedImage
	
		from Blogs_UserFollowingRel as rel
		inner join Timelines_TimelineFeed as tf on tf.CreatedById=rel.FollowedByUserId or tf.CreatedById = @currentUserBaseId
		inner join Users_UserProfile as up on up.UserBaseId=tf.CreatedById
		inner join Users_UserBaseAppRoleRel as ub on ub.UserBaseId=up.UserBaseId 

		where (rel.FollowingUserId = @currentUserBaseId) --or rel.FollowedByUserId = @currentUserBaseId) - if we add this, it posts p/fan
		and tf.IsArchived=0 

		union

		select  
			'Blogs' as TimelineType,
			b.Id,
			case when (LEN(b.BodyText) > 100) then CONCAT(b.Title,'. ',SUBSTRING(b.BodyText, 0, 100),'...') --the : doesn't work for Blogs specifically
			else CONCAT(b.Title,'. ',b.BodyText,'...') 
			end as FeedContent,
			b.IsPublic,
			b.IsSubscriptionOnly,
			b.CreatedDate,
			up.UserBaseId,
			CONCAT (up.FirstName,' ',up.MiddleName,' ',up.LastName) as UserName,
			up.FirstName,
			up.MiddleName,
			up.LastName,
			up.AvatarURL,
			rel.FollowingUserId,
			cast (case when @currentUserBaseId = b.CreatedById then 1 else 0 end as bit) as TimelineOwner,
			(select rel.AppRoleId from Users_UserBase as ub2 join Users_UserBaseAppRoleRel as rel on rel.UserBaseId=ub2.Id where ub2.Id=@currentUserBaseId ) as AppRoleId,
			b.BlogImageUrl as ExtraFeedImage

		from Blogs_Blog as b
		inner join Blogs_UserFollowingRel as rel on rel.FollowedByUserId=b.CreatedById
		inner join Users_UserProfile up on up.UserBaseId=b.CreatedById
		inner join Users_UserBaseAppRoleRel as ubrel on ubrel.UserBaseId=up.UserBaseId
		where rel.FollowingUserId=@currentUserBaseId 

		union

		select 
			'Events' as TimelineType,
			e.Id,
			case when (LEN(e.EventDescription) > 100) then CONCAT(e.EventName,'. ',SUBSTRING(e.EventDescription, 0, 100),'...') 
			else CONCAT(e.EventName,'. ',e.EventDescription,'...') 
			end as FeedContent,	  
			cast (1 as bit) as isPublic,
			cast (0 as bit) as isSubscriptionOnly, 
			e.CreatedDate,
			up.UserBaseId,
			CONCAT (up.FirstName,' ',up.MiddleName,' ',up.LastName) as UserName,
			up.FirstName,
			up.MiddleName,
			up.LastName,
			up.AvatarURL,
			buf.FollowingUserId,
			cast (case when @currentUserBaseId = e.CreatedById then 1 else 0 end as bit) as TimelineOwner,
			(select rel.AppRoleId from Users_UserBase as ub2 join Users_UserBaseAppRoleRel as rel on rel.UserBaseId=ub2.Id where ub2.Id=@currentUserBaseId ) as AppRoleId,
			e.PhotoUrl as ExtraFeedImage

		from Events_ProspectEvent as e
		inner join Blogs_UserFollowingRel as buf on buf.FollowedByUserId=e.CreatedById
		inner join Users_UserProfile up on up.UserBaseId=e.CreatedById
		inner join Users_UserBaseAppRoleRel as ubrel on ubrel.UserBaseId=up.UserBaseId
		where buf.FollowingUserId=@currentUserBaseId

		union

		select
			'Nutrition Plans' as TimelineType,
			n.Id,
			case when (LEN(n.PlanDetails) > 100) then CONCAT(n.PlanName,': ',SUBSTRING(n.PlanDetails, 0, 100),'...') 
			else CONCAT(n.PlanName,': ',n.PlanDetails,'...') 
			end as FeedContent,
			cast (1 as bit) as isPublic, 
			cast (0 as bit) as isSubscriptionOnly, 
			n.CreatedDate,
			up.UserBaseId,
			CONCAT (up.FirstName,' ',up.MiddleName,' ',up.LastName) as UserName,
			up.FirstName,
			up.MiddleName,
			up.LastName,
			up.AvatarURL,
			bufrel.FollowingUserId,
			cast (case when @currentUserBaseId = n.CreatedById then 1 else 0 end AS bit) as TimelineOwner, 
			(select rel.AppRoleId from Users_UserBase as ub2 join Users_UserBaseAppRoleRel as rel on rel.UserBaseId=ub2.Id where ub2.Id=@currentUserBaseId ) as AppRoleId,
			n.PlanImageURL as ExtraFeedImage

		from Nutrition_NutritionPlan as n
		inner join Blogs_UserFollowingRel as bufrel on bufrel.FollowedByUserId=n.CreatedById
		inner join Users_UserProfile as up on up.UserBaseId=n.CreatedById
		inner join Users_UserBaseAppRoleRel as ubrel on ubrel.UserBaseId=up.UserBaseId
		where bufrel.FollowingUserId=@currentUserBaseId

		union

		select
			'Workout Plans' as TimelineType,
			w.Id,
			case when (LEN(w.PlanDetails) > 100) then CONCAT(w.PlanName,': ',SUBSTRING(w.PlanDetails, 0, 100),'...') 
			else CONCAT(w.PlanName,': ',w.PlanDetails,'...') 
			end as FeedContent,
			cast (1 as bit) as isPublic, 
			cast (0 as bit) as isSubscriptionOnly, 
			w.CreatedDate,
			up.UserBaseId,
			CONCAT (up.FirstName,' ',up.MiddleName,' ',up.LastName) as UserName,
			up.FirstName,
			up.MiddleName,
			up.LastName,
			up.AvatarURL,
			ufrel.FollowingUserId,
			cast (case when @currentUserBaseId = w.CreatedById then 1 else 0 end AS bit) as TimelineOwner, 
			(select rel.AppRoleId from Users_UserBase as ub2 join Users_UserBaseAppRoleRel as rel on rel.UserBaseId=ub2.Id where ub2.Id=@currentUserBaseId ) as AppRoleId,
			w.PlanImageURL as ExtraFeedImage

		from Workouts_WorkoutPlan as w
		inner join Blogs_UserFollowingRel as ufrel on ufrel.FollowedByUserId=w.CreatedById
		inner join Users_UserProfile as up on up.UserBaseId=w.CreatedById
		inner join Users_UserBaseAppRoleRel as ubrel on ubrel.UserBaseId=up.UserBaseId
		where ufrel.FollowingUserId=@currentUserBaseId
) 
as tbl
order by CreatedDate desc

if(select count(*) from #timelineFeed) <= 0 begin
	insert into #timelineFeed(TimelineType, Id, FeedContent, 
		isPublic, isSubscriptionOnly, CreatedDate, UserBaseId, UserName, FirstName, 
		MiddleName, LastName, AvatarUrl,FollowingUserId, TimelineOwner,
		AppRoleId,
		ExtraFeedImage)
	select 
		'Status', 0, 'Welcome to Team Prospect! Your journey begins here.',
		1, 0, GetDate(), ub.id, Concat(up.FirstName, up.LastName), up.FirstName,
		up.MiddleName, up.LastName, up.AvatarUrl, @currentUserBaseId, 0,
		0, ''	
	from Users_UserBase ub 
	join Users_UserProfile up on up.UserBaseId=ub.Id
	where ub.Id = 14 -- this is the admins id

	select * from #timelineFeed
end
else begin
	select * from #timelineFeed
	order by CreatedDate desc --testing to fix random order
end


/*
	TEST SCRIPTS
	exec dbo.Timelines_TimelineFeedUserJoin_SelectByUserBaseId	
	@currentUserBaseId = 32
*/	
	
END
