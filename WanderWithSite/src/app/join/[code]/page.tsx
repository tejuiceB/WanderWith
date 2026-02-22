import React from 'react';
import { supabase } from '@/lib/supabase';
import BrandHeader from '@/components/BrandHeader';
import InstallAppBanner from '@/components/InstallAppBanner';
import Image from 'next/image';
import { MapPin, Calendar, Wallet, Map as MapIcon, User, ShieldCheck } from 'lucide-react';
import { Metadata } from 'next';
import JoinTripButton from '@/components/JoinTripButton';

interface TripJoinPageProps {
    params: Promise<{ code: string }>;
}

async function getTrip(code: string) {
    try {
        if (!code) return null;

        let { data: trip, error: codeError } = await supabase
            .from('trips')
            .select('*')
            .eq('join_code', code.toUpperCase())
            .maybeSingle();

        if (codeError) console.error('Error fetching by join_code:', codeError);

        if (!trip) {
            const { data: tripById, error: idError } = await supabase
                .from('trips')
                .select('*')
                .eq('id', code)
                .maybeSingle();
            if (idError) console.error('Error fetching by ID:', idError);
            trip = tripById;
        }

        if (!trip) return null;

        const { data: author } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', trip.created_by)
            .single();

        const { data: days } = await supabase
            .from('trip_days')
            .select('*, trip_plan_places(*)')
            .eq('trip_id', trip.id)
            .order('day_number', { ascending: true });

        return { ...trip, author, days: days || [] };
    } catch (e) {
        console.error('Unexpected exception in getTrip:', e);
        return null;
    }
}

export async function generateMetadata({ params }: TripJoinPageProps): Promise<Metadata> {
    const { code } = await params;
    const trip = await getTrip(code);

    if (!trip) return { title: 'Trip Not Found' };

    return {
        title: `Join ${trip.name} | WanderWith`,
        description: `You've been invited to join ${trip.name}${trip.location ? ` in ${trip.location}` : ''}. View details and join the adventure on WanderWith.`,
    };
}

export const dynamic = 'force-dynamic';

export default async function TripJoinPage({ params }: TripJoinPageProps) {
    const { code } = await params;
    const trip = await getTrip(code);

    if (!trip) {
        return (
            <div className="min-h-screen bg-white flex flex-col">
                <BrandHeader />
                <div className="flex-grow flex items-center justify-center p-6 text-center">
                    <div>
                        <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-6">
                            <MapIcon size={28} className="text-gray-300" />
                        </div>
                        <h1 className="text-2xl font-bold text-gray-800 mb-2">Trip Not Found</h1>
                        <p className="text-gray-500 mb-8 text-sm">This invitation might have expired or the trip was deleted.</p>
                        <a href="/" className="bg-gray-900 text-white px-8 py-3 rounded-lg font-semibold text-sm">Discover WanderWith</a>
                    </div>
                </div>
            </div>
        );
    }

    const startDate = trip.start_date ? new Date(trip.start_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'TBD';
    const endDate = trip.end_date ? new Date(trip.end_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : 'TBD';
    const estimatedCost = trip.metadata?.estimated_cost || 0;
    const budgetAllocations = trip.metadata?.budget_allocations || [];
    const authorName = trip.author?.display_name || trip.author?.username || 'Owner';
    const authorAvatar = trip.author?.avatar_url;
    const initial = authorName[0]?.toUpperCase() || 'O';
    const isAgency = trip.author?.role === 'agency';

    return (
        <div className="min-h-screen bg-white">
            <BrandHeader />

            <div className="pt-20 pb-12">
                <div className="max-w-2xl mx-auto px-4">

                    {/* Trip Header Card */}
                    <div className="bg-gray-50 rounded-2xl border border-gray-100 overflow-hidden">
                        {/* Cover Image */}
                        <div className="relative h-52 md:h-64 w-full bg-gray-200">
                            <Image
                                src={trip.cover_image_url || "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?q=80&w=2021&auto=format&fit=crop"}
                                alt={trip.name}
                                fill
                                className="object-cover"
                            />
                            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />
                            <div className="absolute bottom-0 left-0 w-full p-6">
                                <h1 className="text-3xl md:text-4xl font-bold text-white tracking-tight mb-1">{trip.name}</h1>
                                {trip.location && (
                                    <div className="flex items-center gap-1.5 text-white/80 text-sm">
                                        <MapPin size={14} />
                                        <span>{trip.location}</span>
                                    </div>
                                )}
                            </div>
                        </div>

                        {/* Trip Info */}
                        <div className="p-6">
                            {/* Creator */}
                            <div className="flex items-center gap-3 mb-6">
                                <div className="relative w-10 h-10 rounded-full overflow-hidden bg-gray-200 flex-shrink-0">
                                    {authorAvatar ? (
                                        <Image src={authorAvatar} alt={authorName} fill className="object-cover" />
                                    ) : (
                                        <div className="flex items-center justify-center h-full">
                                            <span className="text-sm font-bold text-gray-400">{initial}</span>
                                        </div>
                                    )}
                                </div>
                                <div>
                                    <p className="text-[11px] text-gray-400 font-bold uppercase tracking-widest">Created by</p>
                                    <div className="flex items-center gap-1">
                                        <p className="font-bold text-gray-900 text-sm">{authorName}</p>
                                        {isAgency && <ShieldCheck size={14} className="text-blue-500" />}
                                    </div>
                                </div>
                            </div>

                            {/* Dates & Budget */}
                            <div className="grid grid-cols-2 gap-4">
                                <div className="bg-white rounded-xl p-4 border border-gray-100">
                                    <div className="flex items-center gap-2 mb-1.5">
                                        <Calendar size={16} className="text-gray-400" />
                                        <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Dates</p>
                                    </div>
                                    <p className="text-sm font-semibold text-gray-800">{startDate} — {endDate}</p>
                                </div>
                                <div className="bg-white rounded-xl p-4 border border-gray-100">
                                    <div className="flex items-center gap-2 mb-1.5">
                                        <Wallet size={16} className="text-gray-400" />
                                        <p className="text-xs font-bold text-gray-400 uppercase tracking-wider">Budget</p>
                                    </div>
                                    <p className="text-sm font-semibold text-gray-800">{trip.budget_currency || '₹'}{estimatedCost} est.</p>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Join CTA */}
                    <div className="mt-6 bg-gray-900 rounded-2xl p-6 text-center">
                        <h3 className="text-xl font-bold text-white mb-2 tracking-tight">Ready to join?</h3>
                        <p className="text-white/60 text-sm mb-5">Open the app to join this trip and start planning together.</p>
                        <JoinTripButton code={code} />
                        <p className="text-[10px] text-white/25 uppercase tracking-widest font-bold mt-4">Requires WanderWith App</p>
                    </div>

                    {/* Itinerary Preview */}
                    <div className="mt-6 bg-gray-50 rounded-2xl border border-gray-100 p-6">
                        <h2 className="text-base font-bold text-gray-900 mb-5 flex items-center gap-2">
                            <MapIcon size={18} className="text-gray-400" />
                            Itinerary Preview
                        </h2>

                        {trip.days.length > 0 ? (
                            <div className="space-y-5">
                                {trip.days.map((day: any) => (
                                    <div key={day.id} className="border-l-2 border-gray-200 pl-5 relative">
                                        <div className="absolute w-3 h-3 rounded-full bg-gray-300 -left-[7px] top-0.5" />
                                        <h4 className="font-bold text-sm text-gray-900 mb-2">
                                            Day {day.day_number} {day.summary ? `— ${day.summary}` : ''}
                                        </h4>
                                        <div className="space-y-1.5">
                                            {day.trip_plan_places?.map((place: any) => (
                                                <div key={place.id} className="flex items-center gap-2 text-sm text-gray-500">
                                                    <span className="w-1.5 h-1.5 rounded-full bg-blue-400 flex-shrink-0" />
                                                    <span>{place.name}</span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : (
                            <p className="text-gray-400 text-sm text-center py-6">No plan details published yet.</p>
                        )}
                    </div>

                    {/* Budget Breakdown */}
                    {budgetAllocations.length > 0 && (
                        <div className="mt-6 bg-gray-50 rounded-2xl border border-gray-100 p-6">
                            <h2 className="text-base font-bold text-gray-900 mb-5 flex items-center gap-2">
                                <Wallet size={18} className="text-gray-400" />
                                Planned Expenses
                            </h2>
                            <div className="space-y-3">
                                {budgetAllocations.map((item: any, idx: number) => (
                                    <div key={idx} className="flex items-center justify-between bg-white rounded-xl px-4 py-3 border border-gray-100">
                                        <span className="text-sm font-medium text-gray-700">{item.category}</span>
                                        <span className="text-sm font-bold text-gray-900">{trip.budget_currency || '₹'}{item.amount}</span>
                                    </div>
                                ))}
                                <div className="border-t border-gray-200 pt-3 mt-4 flex justify-between px-1">
                                    <span className="font-bold text-gray-900">Total Estimate</span>
                                    <span className="font-black text-gray-900">{trip.budget_currency || '₹'}{estimatedCost}</span>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Install Banner */}
                    <div className="mt-8">
                        <InstallAppBanner
                            title="Travel Better. Together."
                            subtitle="WanderWith is built for real connections. Download the app to discover more journeys."
                        />
                    </div>
                </div>
            </div>
        </div>
    );
}
