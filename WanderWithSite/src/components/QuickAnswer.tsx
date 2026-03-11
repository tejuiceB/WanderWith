import { Lightbulb } from "lucide-react";

export default function QuickAnswer({ answer }: { answer: string }) {
    return (
        <div className="bg-brand-bg-alt border border-gray-200 rounded-xl p-6 mb-10">
            <div className="flex items-start gap-3">
                <div className="flex-shrink-0 w-8 h-8 bg-brand-accent/10 rounded-lg flex items-center justify-center mt-0.5">
                    <Lightbulb className="w-4 h-4 text-brand-accent" />
                </div>
                <div>
                    <p className="text-xs font-semibold text-brand-accent uppercase tracking-widest mb-2">
                        Quick Answer
                    </p>
                    <p className="text-gray-700 leading-relaxed text-[15px]">
                        {answer}
                    </p>
                </div>
            </div>
        </div>
    );
}
