import React from 'react';
import { supabase } from '@/lib/supabase';
import BrandHeader from '@/components/BrandHeader';
import InstallAppBanner from '@/components/InstallAppBanner';
import Image from 'next/image';
import { Heart, MessageCircle, Share2, MapPin, ShieldCheck } from 'lucide-react';
import { Metadata } from 'next';
import Link from 'next/link';
import OpenInAppButton from '@/components/OpenInAppButton';

interface PostPageProps {
    params: Promise<{ id: string }>;
}

async function getPost(id: string) {
    try {
        const { data, error } = await supabase
            .from('posts')
            .select('*')
            .eq('id', id)
            .single();

        if (error) {
            console.error('Supabase error fetching post:', error);
            return null;
        }

        if (!data) return null;

        const { data: author } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', data.user_id)
            .single();

        return { ...data, author };
    } catch (e) {
        console.error('Exception in getPost:', e);
        return null;
    }
}

export async function generateMetadata({ params }: PostPageProps): Promise<Metadata> {
    const { id } = await params;
    const post = await getPost(id);

    if (!post) return { title: 'Post Not Found' };

    return {
        title: post.author
            ? `Post by ${post.author.display_name || post.author.username} | WanderWith`
            : "Travel Story | WanderWith",
        description: post.caption || `View this travel post on WanderWith.`,
        openGraph: {
            images: post.image_url ? [post.image_url] : [],
        }
    };
}

export const dynamic = 'force-dynamic';

export default async function PostPage({ params }: PostPageProps) {
    const { id } = await params;
    const post = await getPost(id);

    if (!post) {
        return (
            <div className="min-h-screen bg-white flex flex-col">
                <BrandHeader />
                <div className="flex-grow flex items-center justify-center p-6 text-center">
                    <div>
                        <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center mx-auto mb-6">
                            <Heart size={28} className="text-gray-300" />
                        </div>
                        <h1 className="text-2xl font-bold text-gray-800 mb-2">Post Not Found</h1>
                        <p className="text-gray-500 mb-8 text-sm">This post may have been deleted or is no longer available.</p>
                        <a href="/" className="bg-gray-900 text-white px-8 py-3 rounded-lg font-semibold text-sm">Explore WanderWith</a>
                    </div>
                </div>
            </div>
        );
    }

    const authorName = post.author?.display_name || post.author?.username || 'Traveler';
    const authorAvatar = post.author?.avatar_url;
    const initial = authorName[0]?.toUpperCase() || 'T';
    const isAgency = post.author?.role === 'agency';

    // Parse caption for hashtags
    const renderCaption = (caption: string) => {
        if (!caption) return null;
        const words = caption.split(' ');
        return words.map((word, i) => {
            if (word.startsWith('#') && word.length > 1) {
                return <span key={i} className="text-blue-500 font-semibold">{word} </span>;
            }
            if (word.startsWith('@') && word.length > 1) {
                return <span key={i} className="text-blue-500 font-bold">{word} </span>;
            }
            return <span key={i}>{word} </span>;
        });
    };

    return (
        <div className="min-h-screen bg-white">
            <BrandHeader />

            <div className="pt-20 pb-12">
                <div className="max-w-lg mx-auto px-4">
                    {/* Post Card — matches Flutter PostCard */}
                    <div className="bg-white rounded-3xl shadow-[0_4px_20px_rgba(0,0,0,0.06)] overflow-hidden border border-gray-100">

                        {/* Header */}
                        <div className="flex items-center px-4 py-4">
                            <Link href={`/u/${post.author?.username || ''}`} className="flex items-center gap-3 group flex-grow min-w-0">
                                <div className="relative w-9 h-9 rounded-full overflow-hidden bg-blue-50 flex-shrink-0">
                                    {authorAvatar ? (
                                        <Image
                                            src={authorAvatar}
                                            alt={authorName}
                                            fill
                                            className="object-cover"
                                        />
                                    ) : (
                                        <div className="flex items-center justify-center h-full">
                                            <span className="text-xs font-bold text-blue-500">{initial}</span>
                                        </div>
                                    )}
                                </div>
                                <div className="min-w-0">
                                    <div className="flex items-center gap-1">
                                        <p className="font-bold text-[15px] text-gray-900 truncate">{authorName}</p>
                                        {isAgency && <ShieldCheck className="text-blue-500 flex-shrink-0" size={14} />}
                                    </div>
                                    {post.location && (
                                        <div className="flex items-center gap-0.5">
                                            <MapPin size={10} className="text-blue-500 flex-shrink-0" />
                                            <p className="text-[11px] text-gray-500 truncate">{post.location}</p>
                                        </div>
                                    )}
                                </div>
                            </Link>
                            <OpenInAppButton path={`p/${post.id}`} label="Open" />
                        </div>

                        {/* Image */}
                        {post.image_url && (
                            <div className="relative w-full aspect-square rounded-2xl overflow-hidden mx-0">
                                <Image
                                    src={post.image_url}
                                    alt={post.caption || "Travel Post"}
                                    fill
                                    className="object-cover"
                                    priority
                                    unoptimized
                                />
                                {/* Gradient overlay like the app */}
                                <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black/20 rounded-2xl" />
                            </div>
                        )}

                        {/* Interactions Row */}
                        <div className="flex items-center px-4 py-3">
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-1.5 text-gray-800 hover:text-red-500 transition-colors group"
                            >
                                <Heart size={22} />
                                <span className="text-sm font-bold">{post.like_count || 0}</span>
                            </a>
                            <a
                                href="https://play.google.com/store/apps/details?id=com.tejuice.wanderwith"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-1.5 text-gray-800 hover:text-blue-500 transition-colors ml-5 group"
                            >
                                <MessageCircle size={22} />
                                <span className="text-sm font-bold">{post.comment_count || 0}</span>
                            </a>
                            <div className="flex-grow" />
                            <button className="text-gray-800 hover:text-gray-600 transition-colors">
                                <Share2 size={20} />
                            </button>
                        </div>

                        {/* Caption */}
                        {post.caption && (
                            <div className="px-4 pb-4">
                                <p className="text-[15px] text-gray-800 leading-relaxed">
                                    {renderCaption(post.caption)}
                                </p>
                            </div>
                        )}
                    </div>

                    {/* Install Banner */}
                    <div className="mt-8">
                        <InstallAppBanner
                            title="Love this story?"
                            subtitle="Download the app to share your reaction and connect with this traveler."
                        />
                    </div>
                </div>
            </div>
        </div>
    );
}
