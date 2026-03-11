export interface DocSection {
    id: string;
    title: string;
    items: DocItem[];
}

export interface DocItem {
    id: string;
    title: string;
    content: string;
}

export const docSections: DocSection[] = [
    {
        id: "getting-started",
        title: "Getting Started",
        items: [
            {
                id: "overview",
                title: "Overview",
                content: `
                    <p>WanderWith is a free social travel planning app built for group travellers. It brings itinerary planning, group collaboration, budget tracking, and shared memories into one place so you can focus on enjoying the journey instead of managing logistics.</p>
                    <p>Whether you're planning a weekend getaway with friends, a family vacation across multiple cities, or a college reunion trip, WanderWith handles the planning while you handle the fun.</p>
                    <div class="doc-tip">
                        <strong>Good to know</strong>
                        <p>WanderWith is completely free. No ads, no premium tiers, no hidden charges. Every feature mentioned in this documentation is available to all users at no cost.</p>
                    </div>
                    <h3>What you can do with WanderWith</h3>
                    <ul>
                        <li>Create trip plans with AI-generated itineraries</li>
                        <li>Invite friends and plan together in real-time</li>
                        <li>Chat within trip groups</li>
                        <li>Track expenses and split costs</li>
                        <li>Vote on decisions with polls</li>
                        <li>Share trip photos in collaborative galleries</li>
                        <li>Access everything offline</li>
                    </ul>
                `,
            },
            {
                id: "download-app",
                title: "Download the App",
                content: `
                    <p>WanderWith is available as a free download on both major platforms.</p>
                    <h3>Android</h3>
                    <p>Download WanderWith from the <a href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith" target="_blank" rel="noopener noreferrer">Google Play Store</a>. Search for "WanderWith" or use the direct link from the homepage.</p>
                    <h3>iOS</h3>
                    <p>WanderWith is available on the App Store for iPhone and iPad.</p>
                    <div class="doc-note">
                        <strong>Requirements</strong>
                        <p>Android 8.0 or later. iOS 14.0 or later. Internet connection required for initial setup and sync. Offline access works after first sync.</p>
                    </div>
                `,
            },
            {
                id: "create-account",
                title: "Create an Account",
                content: `
                    <p>Getting started takes less than 30 seconds.</p>
                    <h3>Sign up with Google</h3>
                    <p>Tap "Continue with Google" on the login screen. This is the fastest option — your name and profile photo are imported automatically.</p>
                    <h3>Sign up with Email</h3>
                    <p>Enter your email address and create a password. You'll receive a verification email to confirm your account.</p>
                    <div class="doc-tip">
                        <strong>Tip</strong>
                        <p>Google sign-in is recommended for the smoothest experience. It also makes it easier for friends to find and invite you to trips.</p>
                    </div>
                    <h3>Set up your profile</h3>
                    <p>After signing up, add a username and optionally a profile photo. Your username helps friends find you when they want to invite you to a trip.</p>
                `,
            },
            {
                id: "create-first-trip",
                title: "Create Your First Trip",
                content: `
                    <p>Creating a trip is the starting point for everything in WanderWith.</p>
                    <h3>Step-by-step</h3>
                    <ol>
                        <li>Open WanderWith and tap the <strong>+</strong> button on the home screen</li>
                        <li>Enter your destination (city, country, or region)</li>
                        <li>Set your travel dates</li>
                        <li>Optionally set a budget for the trip</li>
                        <li>Choose whether to generate an AI itinerary or start blank</li>
                    </ol>
                    <p>Once created, your trip becomes a shared workspace. You can invite friends, add activities, track expenses, and collaborate in real-time.</p>
                    <div class="doc-tip">
                        <strong>Tip</strong>
                        <p>If you're not sure about exact dates yet, you can always change them later. Creating the trip first and inviting friends gets the planning momentum going.</p>
                    </div>
                `,
            },
        ],
    },
    {
        id: "trip-planning",
        title: "Trip Planning",
        items: [
            {
                id: "ai-itinerary",
                title: "AI Itinerary Generation",
                content: `
                    <p>WanderWith's AI creates complete day-by-day travel plans based on your destination, dates, budget, and preferences. Think of it as having a knowledgeable local friend who plans your entire trip for you.</p>
                    <h3>How to generate an AI itinerary</h3>
                    <ol>
                        <li>Open a trip (or create a new one)</li>
                        <li>Tap <strong>"Generate AI Itinerary"</strong></li>
                        <li>Confirm your destination and dates</li>
                        <li>Select your travel style (relaxed, balanced, packed)</li>
                        <li>Review the generated plan</li>
                    </ol>
                    <p>The AI suggests places to visit, restaurants to try, activities to do, and a logical order that minimises travel time between locations.</p>
                    <h3>What the AI considers</h3>
                    <ul>
                        <li>Opening hours and seasonal availability</li>
                        <li>Geographic proximity to reduce travel time</li>
                        <li>Budget constraints</li>
                        <li>Group size and travel preferences</li>
                        <li>Popular landmarks and hidden gems</li>
                    </ul>
                    <h3>Customising the itinerary</h3>
                    <p>Every part of the AI-generated plan is fully editable. Add activities, remove suggestions, rearrange the order, or swap entire days. The AI gives you a solid starting point — you make it yours.</p>
                    <div class="doc-note">
                        <strong>Note</strong>
                        <p>AI itinerary generation requires an internet connection. Once generated, the itinerary is cached locally and available offline.</p>
                    </div>
                `,
            },
            {
                id: "add-destinations",
                title: "Add Destinations & Activities",
                content: `
                    <p>Build your itinerary manually by adding places and activities day by day.</p>
                    <h3>Adding a destination</h3>
                    <ol>
                        <li>Open your trip and navigate to the itinerary tab</li>
                        <li>Tap <strong>"Add Place"</strong> on the day you want</li>
                        <li>Search for a place or enter it manually</li>
                        <li>Add optional details like time, notes, and booking links</li>
                    </ol>
                    <h3>Organising your day</h3>
                    <p>Drag and drop activities to reorder them. WanderWith displays locations on a map so you can see if your day's plan makes geographic sense.</p>
                    <div class="doc-tip">
                        <strong>Tip</strong>
                        <p>Combine AI generation with manual additions. Generate the base itinerary with AI, then add your own must-visit spots and personal recommendations.</p>
                    </div>
                `,
            },
            {
                id: "travel-timeline",
                title: "Travel Timeline",
                content: `
                    <p>The timeline view gives you a visual overview of your entire trip, day by day.</p>
                    <h3>Timeline features</h3>
                    <ul>
                        <li>See all days at a glance with activity summaries</li>
                        <li>Colour-coded activities by type (sightseeing, food, transport)</li>
                        <li>Tap any day to expand and see full details</li>
                        <li>Quickly identify empty days or overpacked schedules</li>
                    </ul>
                    <p>The timeline syncs in real-time across all group members, so everyone always sees the latest version of the plan.</p>
                `,
            },
        ],
    },
    {
        id: "group-trips",
        title: "Group Trips",
        items: [
            {
                id: "invite-friends",
                title: "Invite Friends",
                content: `
                    <p>WanderWith is built for group travel. Inviting friends to your trip takes seconds.</p>
                    <h3>How to invite</h3>
                    <ol>
                        <li>Open your trip</li>
                        <li>Tap the <strong>members icon</strong> or <strong>"Invite"</strong></li>
                        <li>Share the invite link via WhatsApp, text, email, or any messaging app</li>
                    </ol>
                    <p>Friends click the link, sign in to WanderWith, and they're instantly added to the trip. No invite codes to remember, no complicated setup.</p>
                    <h3>Group size</h3>
                    <p>There's no limit on group size. Whether it's 2 people or 50, all features work the same. WanderWith handles groups of any size without performance issues.</p>
                    <div class="doc-tip">
                        <strong>Tip</strong>
                        <p>Send the invite link early, even before the trip is fully planned. Getting everyone into the trip early means more people contribute ideas from the start.</p>
                    </div>
                `,
            },
            {
                id: "group-voting",
                title: "Polls & Group Voting",
                content: `
                    <p>Group decisions are the hardest part of planning. Polls make them easy.</p>
                    <h3>When to use polls</h3>
                    <ul>
                        <li>Choosing between destinations</li>
                        <li>Picking a hotel or Airbnb</li>
                        <li>Deciding on restaurants</li>
                        <li>Voting on activities</li>
                        <li>Settling any group disagreement</li>
                    </ul>
                    <h3>Creating a poll</h3>
                    <ol>
                        <li>Open your trip</li>
                        <li>Tap <strong>"Create Poll"</strong></li>
                        <li>Add a question and options</li>
                        <li>Choose visible or anonymous voting</li>
                        <li>Share with the group</li>
                    </ol>
                    <p>Results update in real-time. Once enough people have voted, the group can move forward with a clear decision.</p>
                `,
            },
            {
                id: "trip-chat",
                title: "Trip Chat",
                content: `
                    <p>Every trip has a built-in group chat. No more switching between WhatsApp and your planning tool.</p>
                    <h3>Chat features</h3>
                    <ul>
                        <li>Dedicated chat for each trip</li>
                        <li>@mention specific people to get their attention</li>
                        <li>React to messages with emojis</li>
                        <li>Share photos, links, and media</li>
                        <li>All conversations stay connected to the trip context</li>
                    </ul>
                    <p>The biggest advantage over WhatsApp is organisation. Trip chat messages stay with the trip, not buried under months of unrelated personal messages.</p>
                    <div class="doc-note">
                        <strong>Note</strong>
                        <p>Chat messages sync in real-time when online. When offline, messages are queued and sent automatically when you reconnect.</p>
                    </div>
                `,
            },
        ],
    },
    {
        id: "budget-expenses",
        title: "Budget & Expenses",
        items: [
            {
                id: "budget-tracking",
                title: "Budget Tracking",
                content: `
                    <p>Track every expense and stay on top of your trip budget in real-time.</p>
                    <h3>Setting a trip budget</h3>
                    <p>When creating a trip (or anytime after), set an overall budget. As expenses are added, WanderWith shows a real-time comparison of planned spending versus actual spending.</p>
                    <h3>Adding expenses</h3>
                    <ol>
                        <li>Open the budget tab in your trip</li>
                        <li>Tap <strong>"Add Expense"</strong></li>
                        <li>Enter the amount, category, and who paid</li>
                        <li>The expense is instantly visible to all group members</li>
                    </ol>
                    <h3>Expense categories</h3>
                    <p>Organise expenses by type — accommodation, food, transport, activities, shopping, and more. This makes it easy to see where the most money is going.</p>
                `,
            },
            {
                id: "split-expenses",
                title: "Expense Splitting",
                content: `
                    <p>No more awkward end-of-trip money conversations. WanderWith calculates who owes whom automatically.</p>
                    <h3>How splitting works</h3>
                    <p>When someone pays for a shared expense (restaurant, taxi, hotel), add it to the trip with the amount and who paid. WanderWith calculates the simplest way for everyone to settle up.</p>
                    <h3>Split types</h3>
                    <ul>
                        <li><strong>Equal split</strong> — divide evenly among all members</li>
                        <li><strong>Custom split</strong> — assign different amounts to different people</li>
                        <li><strong>Exclude members</strong> — leave out people who weren't involved</li>
                    </ul>
                    <div class="doc-tip">
                        <strong>Tip</strong>
                        <p>Add expenses as they happen during the trip, not after. Real-time tracking prevents misunderstandings and keeps everyone informed about spending.</p>
                    </div>
                `,
            },
        ],
    },
    {
        id: "media-memories",
        title: "Media & Memories",
        items: [
            {
                id: "photo-gallery",
                title: "Shared Photo Gallery",
                content: `
                    <p>Every trip has a shared photo gallery where all members can upload and view trip photos in one place.</p>
                    <h3>How it works</h3>
                    <ul>
                        <li>Open the gallery tab in your trip</li>
                        <li>Upload photos from your device</li>
                        <li>All trip members can contribute their photos</li>
                        <li>React to photos with emojis</li>
                        <li>View all trip memories in a timeline</li>
                    </ul>
                    <p>The gallery solves the classic problem of trip photos being scattered across everyone's individual phones. One shared album, all the memories.</p>
                    <h3>Downloading photos</h3>
                    <p>Download individual photos or browse the complete trip album. All photos are stored securely and accessible anytime.</p>
                `,
            },
        ],
    },
    {
        id: "agencies",
        title: "Travel Agencies",
        items: [
            {
                id: "agency-dashboard",
                title: "Agency Dashboard",
                content: `
                    <p>WanderWith includes professional tools for travel agencies to create packages, manage clients, and grow their business.</p>
                    <h3>Setting up your agency</h3>
                    <ol>
                        <li>Create a WanderWith account</li>
                        <li>Apply for agency access through the app</li>
                        <li>Once approved, access the agency dashboard</li>
                    </ol>
                    <h3>Agency features</h3>
                    <ul>
                        <li><strong>Create trip packages</strong> — build professional itineraries with pricing</li>
                        <li><strong>Publish publicly</strong> — make packages discoverable to all WanderWith users</li>
                        <li><strong>Manage clients</strong> — track bookings and communicate with travellers</li>
                        <li><strong>Branded itineraries</strong> — share itineraries with your agency branding</li>
                        <li><strong>Track status</strong> — monitor bookings and trip progress</li>
                    </ul>
                    <div class="doc-tip">
                        <strong>Tip</strong>
                        <p>Publish trips with detailed itineraries and clear pricing. The more information you provide, the more likely travellers are to book.</p>
                    </div>
                `,
            },
        ],
    },
    {
        id: "privacy-security",
        title: "Privacy & Security",
        items: [
            {
                id: "privacy-data",
                title: "Privacy & Data",
                content: `
                    <p>WanderWith is privacy-first by design. Here's exactly what that means.</p>
                    <h3>No ads</h3>
                    <p>There are no advertisements anywhere in the app. WanderWith will never show you ads.</p>
                    <h3>No tracking</h3>
                    <p>WanderWith does not track user behaviour or sell analytics data to third parties. Your usage patterns stay private.</p>
                    <h3>No data selling</h3>
                    <p>Your travel data, trip plans, photos, and personal information are never sold or shared with advertisers, data brokers, or any third party.</p>
                    <h3>Private by default</h3>
                    <p>All trips are private by default. Only people you explicitly invite can see your trip details. WanderWith never makes your content public without your consent.</p>
                    <h3>Account deletion</h3>
                    <p>You can delete your account at any time from the app settings. This permanently removes all your data from our servers, including trips, photos, and personal information.</p>
                `,
            },
        ],
    },
    {
        id: "help",
        title: "Help",
        items: [
            {
                id: "troubleshooting",
                title: "Troubleshooting",
                content: `
                    <h3>App isn't syncing</h3>
                    <p>Check your internet connection. WanderWith needs internet for real-time sync. If you're offline, changes save locally and sync automatically when you reconnect.</p>
                    <h3>Can't find the invite link</h3>
                    <p>Open your trip, tap the members or people icon, then tap "Invite". You'll see options to share the invite link via any messaging app.</p>
                    <h3>AI itinerary isn't generating</h3>
                    <p>AI generation requires a stable internet connection. If it fails, check your connection and try again. If the issue persists, try with a different destination name.</p>
                    <h3>Photos not uploading</h3>
                    <p>Ensure WanderWith has permission to access your photos. Check your device settings under app permissions. Also verify you have a stable internet connection.</p>
                    <h3>Contact support</h3>
                    <p>For any issues not covered here, email us at <a href="mailto:wanderwithplan@gmail.com">wanderwithplan@gmail.com</a>. We respond within 24 hours.</p>
                `,
            },
        ],
    },
];
