import React from 'react';
import { supabase } from '@/lib/supabase';
import BrandHeader from '@/components/BrandHeader';
import InstallAppBanner from '@/components/InstallAppBanner';
import Image from 'next/image';
import { MapPin, Globe, Lock, ShieldCheck, Users, UserPlus, Map as MapIcon } from 'lucide-react';
import { Metadata } from 'next';
import OpenInAppButton from '@/components/OpenInAppButton';

interface ProfilePageProps {
    params: Promise<{ username: string }>;
}

async function getProfile(username: string) {
    try {
        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('username', username)
            .single();

        if (error) {
            console.error('Error fetching profile:', error);
            return null;
        }
        return data;
    } catch (e) {
        console.error('Exception in getProfile:', e);
        return null;
    }
}

export async function generateMetadata({ params }: ProfilePageProps): Promise<Metadata> {
    const { username } = await params;
    const profile = await getProfile(username);

    if (!profile) return { title: 'Profile Not Found | WanderWith' };

    const name = profile.display_name || profile.username || username;
    return {
        title: `${name} | WanderWith`,
        description: profile.bio || `Check out ${name}'s profile on WanderWith.`,
    };
}

export const dynamic = 'force-dynamic';

export default async function ProfilePage({ params }: ProfilePageProps) {
    const { username } = await params;
    const profile = await getProfile(username);

    if (!profile) {
        return (
            <div className="min-h-screen bg-white flex flex-col">
                <BrandHeader />
                <div className="flex-grow flex items-center justify-center p-6 text-center">
                    <div>
                        <div className="w-20 h-20 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-6">
                            <Users size={36} className="text-gray-300" />
                        </div>
                        <h1 className="text-2xl font-bold text-gray-800 mb-2" style={{ fontFamily: 'var(--font-sans)' }}>User Not Found</h1>
                        <p className="text-gray-500 mb-8">The profile @{username} does not exist.</p>
                        <a href="/" className="bg-gray-900 text-white px-8 py-3 rounded-lg font-semibold text-sm">Go Back</a>
                    </div>
                </div>
            </div>
        );
    }

    const isPrivate = profile.is_private && profile.role !== 'agency';
    const isAgency = profile.role === 'agency';
    const displayName = profile.display_name || username;
    const initial = displayName ? displayName[0].toUpperCase() : 'U';
    const location = [profile.city, profile.country].filter(Boolean).join(', ');
    const interests: string[] = profile.interests || [];

    return (
        <div className="min-h-screen bg-white">
            <BrandHeader />

            <div className="pt-20">
                {/* Agency Cover Photo */}
                {isAgency && (
                    <div className="relative h-48 md:h-56 w-full bg-gray-100">
                        {profile.cover_image_url ? (
                            <Image
                                src={profile.cover_image_url}
                                alt="Cover"
                                fill
                                className="object-cover"
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full">
                                <ShieldCheck size={48} className="text-gray-300" />
                            </div>
                        )}
                    </div>
                )}

                {/* Profile Content */}
                <div className={`max-w-lg mx-auto px-6 ${isAgency ? '-mt-14' : 'pt-10'}`}>
                    {/* Avatar */}
                    <div className="flex justify-center">
                        <div className={`relative ${isAgency ? 'w-28 h-28' : 'w-28 h-28'} rounded-full overflow-hidden border-4 border-white shadow-lg bg-gray-100`}>
                            {profile.avatar_url ? (
                                <Image
                                    src={profile.avatar_url}
                                    alt={displayName}
                                    fill
                                    className="object-cover"
                                />
                            ) : (
                                <div className="flex items-center justify-center h-full">
                                    <span className="text-3xl font-bold text-gray-400">{initial}</span>
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Name + Username */}
                    <div className="text-center mt-5">
                        <div className="flex items-center justify-center gap-2">
                            <h1 className="text-2xl font-bold text-gray-900 tracking-tight">{displayName}</h1>
                            {isAgency && (
                                <ShieldCheck className="text-blue-500" size={20} />
                            )}
                        </div>
                        <p className="text-gray-500 font-medium text-sm mt-1">@{profile.username}</p>
                    </div>

                    {/* Bio */}
                    {profile.bio && (
                        <p className="text-center text-gray-700 mt-4 text-[15px] leading-relaxed max-w-sm mx-auto">
                            {profile.bio}
                        </p>
                    )}

                    {/* Location */}
                    {location && (
                        <div className="flex items-center justify-center gap-1.5 mt-3 text-gray-500 text-sm">
                            <MapPin size={14} className="text-gray-400" />
                            <span>{location}</span>
                        </div>
                    )}

                    {/* Open in App Button */}
                    <div className="flex justify-center mt-6">
                        <OpenInAppButton path={`u/${profile.username}`} />
                    </div>

                    {/* Stats Row */}
                    <div className="mt-8 bg-gray-50 rounded-2xl border border-gray-100 py-5 px-4">
                        <div className="flex justify-evenly">
                            <div className="text-center">
                                <p className="text-xl font-bold text-gray-900">{profile.followers_count || 0}</p>
                                <p className="text-xs text-gray-500 font-medium mt-0.5">Followers</p>
                            </div>
                            <div className="w-px bg-gray-200 self-stretch" />
                            <div className="text-center">
                                <p className="text-xl font-bold text-gray-900">{profile.following_count || 0}</p>
                                <p className="text-xs text-gray-500 font-medium mt-0.5">Following</p>
                            </div>
                            <div className="w-px bg-gray-200 self-stretch" />
                            <div className="text-center">
                                <p className="text-xl font-bold text-gray-900">{profile.trips_count || 0}</p>
                                <p className="text-xs text-gray-500 font-medium mt-0.5">Trips</p>
                            </div>
                        </div>
                    </div>

                    {/* Interests Tags */}
                    {interests.length > 0 && (
                        <div className="mt-6">
                            <div className="flex flex-wrap justify-center gap-2">
                                {interests.map((interest: string) => (
                                    <span
                                        key={interest}
                                        className="bg-gray-100 text-gray-600 text-xs font-semibold px-3.5 py-1.5 rounded-full border border-gray-200"
                                    >
                                        {interest}
                                    </span>
                                ))}
                            </div>
                        </div>
                    )}

                    {/* Content Section */}
                    <div className="mt-8 mb-12">
                        {isPrivate ? (
                            <div className="bg-gray-50 rounded-2xl p-10 text-center border border-gray-100 flex flex-col items-center">
                                <Lock className="text-gray-300 mb-4" size={48} />
                                <h3 className="text-base font-bold text-gray-800 mb-2">This account is private</h3>
                                <p className="text-gray-500 text-sm mb-1">Follow this traveler in the app to see their posts and journeys.</p>
                            </div>
                        ) : (
                            <div className="bg-gray-50 rounded-2xl p-10 text-center border border-gray-100 flex flex-col items-center">
                                <MapIcon className="text-gray-300 mb-4" size={40} />
                                <p className="text-gray-500 text-sm">Posts and trip history are available in the WanderWith app.</p>
                            </div>
                        )}
                    </div>

                    {/* Install Banner */}
                    <div className="mb-12">
                        <InstallAppBanner
                            title={`Connect with ${displayName}`}
                            subtitle="Download WanderWith to follow, message, and plan future adventures together."
                        />
                    </div>
                </div>
            </div>
        </div>
    );
}
