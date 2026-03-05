
# Location Share Android application privacy policy

Application collects approximate and precise location data from the users phone when the location sharing is activated.

To do so, location permission has to be set "Location permission" > "Allow all the time" and in addition "Use precise location" has to be active.

The collected location data is timestamped and saved via API to PostgreSQL database so that the event managers could track the user location during the event.

Application cannot be used without first creating a valid event and the event does have manager set Expiration date and the Android application access has even shorter default access time, based on the event details.

In the system, 90 day data deleting deadline is implemented.

Users / team members / other participants other than the event organizers do not have access to the data and even they do not have access to raw data.

When the user of the application disables the location sharing, the data collection does end and the user cannot be further tracked.