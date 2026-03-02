import React from 'react';
import { supabase } from '@/lib/supabase';
import BrandHeader from '@/components/BrandHeader';
import InstallAppBanner from '@/components/InstallAppBanner';
import OpenInAppButton from '@/components/OpenInAppButton';
import { MapPin, Calendar, Users, Plane } from 'lucide-react';
import { Metadata } from 'next';

interface TripPageProps {
    params: Promise<{ tripId: string }>;
}

async function getTrip(tripId: string) {
    try {
        const { data, error } = await supabase
            .from('trips')
            .select('id, name, location, start_date, end_date, status, members')
            .eq('id', tripId)
            .single();

        if (error) {
            console.error('Error fetching trip:', error);
            return null;
        }
        return data;
    } catch (e) {
        console.error('Exception in getTrip:', e);
        return null;
    }
}

function formatDate(dateStr: string | null): string {
    if (!dateStr) return '';
    try {
        return new Date(dateStr).toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
        });
    } catch {
        return dateStr;
    }
}

export async function generateMetadata({ params }: TripPageProps): Promise<Metadata> {
    const { tripId } = await params;
    const trip = await getTrip(tripId);

    if (!trip) return { title: 'Trip Not Found | WanderWith' };

    const name = trip.name || 'Untitled Trip';
    const location = trip.location || '';
    const desc = location
        ? `${name} — ${location}. Plan, share and manage this trip on WanderWith.`
        : `${name}. Plan, share and manage this trip on WanderWith.`;

    return {
        title: `${name} | WanderWith`,
        description: desc,
        openGraph: {
            title: `${name} | WanderWith`,
            description: desc,
            type: 'website',
            url: `https://wanderwith.online/trip/${tripId}`,
        },
    };
}

export const dynamic = 'force-dynamic';

export default async function TripPage({ params }: TripPageProps) {
    const { tripId } = await params;
    const trip = await getTrip(tripId);

    if (!trip) {
        return (
            <div className="min-h-screen bg-white flex flex-col">
                <BrandHeader />
                <div className="flex-grow flex items-center justify-center p-6 text-center">
                    <div>
                        <div className="w-20 h-20 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-6">
                            <Plane size={36} className="text-gray-300" />
                        </div>
                        <h1 className="text-2xl font-bold text-gray-800 mb-2">Trip Not Found</h1>
                        <p className="text-gray-500 max-w-sm mx-auto">
                            This trip may have been deleted or the link is incorrect.
                        </p>
                    </div>
                </div>
                <InstallAppBanner />
            </div>
        );
    }

    const name = trip.name || 'Untitled Trip';
    const location = trip.location || null;
    const startDate = formatDate(trip.start_date);
    const endDate = formatDate(trip.end_date);
    const dateRange = startDate && endDate ? `${startDate} — ${endDate}` : startDate || endDate || null;
    const memberCount = Array.isArray(trip.members) ? trip.members.length : null;

    return (
        <div className="min-h-screen bg-gradient-to-br from-white via-gray-50 to-white flex flex-col">
            <BrandHeader />

            <main className="flex-grow flex items-center justify-center p-6">
                <div className="w-full max-w-md">
                    {/* Trip Card */}
                    <div className="bg-white rounded-3xl shadow-xl border border-gray-100 overflow-hidden">
                        {/* Header Band */}
                        <div className="bg-gradient-to-r from-[#6C63FF] to-[#8B83FF] p-6 text-white">
                            <div className="flex items-center gap-2 mb-1 opacity-80 text-sm font-medium">
                                <Plane size={16} />
                                <span>WanderWith Trip</span>
                            </div>
                            <h1 className="text-2xl font-bold leading-tight">{name}</h1>
                        </div>

                        {/* Trip Details */}
                        <div className="p-6 space-y-4">
                            {location && (
                                <div className="flex items-center gap-3 text-gray-700">
                                    <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
                                        <MapPin size={18} className="text-[#6C63FF]" />
                                    </div>
                                    <span className="font-medium">{location}</span>
                                </div>
                            )}
                            {dateRange && (
                                <div className="flex items-center gap-3 text-gray-700">
                                    <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
                                        <Calendar size={18} className="text-[#6C63FF]" />
                                    </div>
                                    <span className="font-medium">{dateRange}</span>
                                </div>
                            )}
                            {memberCount && memberCount > 0 && (
                                <div className="flex items-center gap-3 text-gray-700">
                                    <div className="w-9 h-9 rounded-xl bg-purple-50 flex items-center justify-center flex-shrink-0">
                                        <Users size={18} className="text-[#6C63FF]" />
                                    </div>
                                    <span className="font-medium">
                                        {memberCount} {memberCount === 1 ? 'traveler' : 'travelers'}
                                    </span>
                                </div>
                            )}

                            {/* CTA */}
                            <div className="pt-4 flex flex-col items-center gap-3">
                                <OpenInAppButton path={`trip/${tripId}`} label="Open Trip in App" />
                                <p className="text-xs text-gray-400 text-center">
                                    View the full itinerary, budget, and more in WanderWith
                                </p>
                            </div>
                        </div>
                    </div>

                    {/* Branding Footer */}
                    <p className="text-center text-xs text-gray-400 mt-6">
                        Planned with <span className="font-semibold text-[#6C63FF]">WanderWith</span>
                    </p>
                </div>
            </main>

            <InstallAppBanner />
        </div>
    );
}
