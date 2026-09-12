// Intro event for The Sworn Five.
this.sworn_five_intro_event <- this.inherit("scripts/events/event", {
	m = {},
	function create()
	{
		this.m.ID = "event.sworn_five_intro";
		this.m.IsSpecial = true;
		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_76.png[/img]The twins are arguing about wind again. Halvard has the spear across his knees and is not listening. Bram is counting the coin for the third time, because Bram counts everything three times, and that is why the four of you are still alive.\n\nSable is not there. Sable is never there until it matters, and then there is a body on the ground and the knife is already clean.\n\nFive of you, an oath older than any contract, and a road that runs to a village with a board full of work. Nobody says anything about it. Nobody has to.",
			Image = "",
			Banner = "",
			List = [],
			Characters = [],
			Options = [
				{
					Text = "Same as always. Together.",
					function getResult( _event )
					{
						return 0;
					}
				}
			],
			function start( _event )
			{
			}
		});
	}

	function onUpdateScore()
	{
		return;
	}

	function onPrepare()
	{
		this.m.Title = "The Sworn Five";
	}

	function onPrepareVariables( _vars )
	{
	}

	function onClear()
	{
		::Time.scheduleEvent(::TimeUnit.Real, 200, function ( _tag )
		{
			if (("State" in ::World) && ::World.State != null) ::World.State.setPause(false);
		}, null);
	}
});
